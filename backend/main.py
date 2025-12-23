"""
Household Digital Twins - Bookshelf API
FastAPI server for managing a digital twin of your bookshelf
"""
import os
from contextlib import asynccontextmanager
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional
from pydantic import BaseModel

from models import Book, Bookshelf, BookshelfManager
from services import detect_books_in_image, enrich_books_with_covers


# Initialize bookshelf manager
bookshelf_manager = BookshelfManager()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan - startup and shutdown events"""
    # Startup: verify Anthropic API key is set
    if not os.getenv("ANTHROPIC_API_KEY"):
        print("WARNING: ANTHROPIC_API_KEY environment variable not set!")
        print("Book detection from images will not work without it.")
    yield
    # Shutdown: nothing to clean up


app = FastAPI(
    title="Household Digital Twins - Bookshelf API",
    description="API for managing a digital twin of your bookshelf using AI vision",
    version="1.0.0",
    lifespan=lifespan
)

# Configure CORS for iOS app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, restrict this to your iOS app's origin
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================================
# Response Models
# ============================================================================

class ScanResponse(BaseModel):
    """Response from scanning a bookshelf image"""
    message: str
    books_detected: int
    books_added: int
    bookshelf: Bookshelf


class BookshelfResponse(BaseModel):
    """Response containing bookshelf data"""
    bookshelf: Bookshelf
    total_books: int


class HealthResponse(BaseModel):
    """Health check response"""
    status: str
    anthropic_configured: bool


# ============================================================================
# Endpoints
# ============================================================================

@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Check API health and configuration status"""
    return HealthResponse(
        status="healthy",
        anthropic_configured=bool(os.getenv("ANTHROPIC_API_KEY"))
    )


@app.post("/scan", response_model=ScanResponse)
async def scan_bookshelf(image: UploadFile = File(...)):
    """
    Scan an image of a bookshelf to detect and add books
    
    - Accepts image files (JPEG, PNG, GIF, WEBP)
    - Uses Claude Vision to detect book titles and authors
    - Fetches book covers from OpenLibrary
    - Adds detected books to the digital twin
    """
    # Validate file type
    allowed_types = ["image/jpeg", "image/png", "image/gif", "image/webp"]
    if image.content_type not in allowed_types:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type. Allowed types: {', '.join(allowed_types)}"
        )
    
    # Check if Anthropic is configured
    if not os.getenv("ANTHROPIC_API_KEY"):
        raise HTTPException(
            status_code=503,
            detail="Anthropic API key not configured. Cannot process images."
        )
    
    # Read image data
    image_data = await image.read()
    
    # Detect books using Claude Vision
    try:
        detection_result = await detect_books_in_image(
            image_data=image_data,
            media_type=image.content_type
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error analyzing image: {str(e)}"
        )
    
    if not detection_result.books:
        return ScanResponse(
            message="No books detected in the image",
            books_detected=0,
            books_added=0,
            bookshelf=bookshelf_manager.get_bookshelf()
        )
    
    # Enrich books with cover URLs from OpenLibrary
    books_data = [{"title": b.title, "author": b.author} for b in detection_result.books]
    enriched_books = await enrich_books_with_covers(books_data)
    
    # Convert to Book models and add to bookshelf
    books_to_add = [
        Book(
            title=b["title"],
            author=b["author"],
            cover_url=b["cover_url"]
        )
        for b in enriched_books
    ]
    
    updated_bookshelf = bookshelf_manager.add_books(books_to_add)
    
    return ScanResponse(
        message=f"Successfully detected {len(detection_result.books)} books",
        books_detected=len(detection_result.books),
        books_added=len(books_to_add),
        bookshelf=updated_bookshelf
    )


@app.get("/bookshelf", response_model=BookshelfResponse)
async def get_bookshelf():
    """
    Get the current state of the bookshelf digital twin
    
    Returns all books with their titles, authors, and cover URLs
    """
    bookshelf = bookshelf_manager.get_bookshelf()
    return BookshelfResponse(
        bookshelf=bookshelf,
        total_books=len(bookshelf.books)
    )


@app.delete("/bookshelf")
async def clear_bookshelf():
    """
    Clear all books from the bookshelf
    
    Use with caution - this removes all stored books
    """
    bookshelf = bookshelf_manager.clear_bookshelf()
    return {
        "message": "Bookshelf cleared",
        "bookshelf": bookshelf
    }


class RemoveBookRequest(BaseModel):
    """Request to remove a specific book"""
    title: str
    author: str


@app.delete("/bookshelf/book")
async def remove_book(request: RemoveBookRequest):
    """
    Remove a specific book from the bookshelf
    """
    bookshelf = bookshelf_manager.remove_book(request.title, request.author)
    return {
        "message": f"Removed '{request.title}' by {request.author}",
        "bookshelf": bookshelf
    }


class AddBookRequest(BaseModel):
    """Request to manually add a book"""
    title: str
    author: str
    cover_url: Optional[str] = None


@app.post("/bookshelf/book")
async def add_book(request: AddBookRequest):
    """
    Manually add a book to the bookshelf
    
    Optionally fetches cover from OpenLibrary if not provided
    """
    cover_url = request.cover_url
    
    # Fetch cover if not provided
    if not cover_url:
        from services import get_book_cover_url
        cover_url = await get_book_cover_url(request.title, request.author)
    
    book = Book(
        title=request.title,
        author=request.author,
        cover_url=cover_url
    )
    
    bookshelf = bookshelf_manager.add_books([book])
    
    return {
        "message": f"Added '{request.title}' by {request.author}",
        "book": book,
        "bookshelf": bookshelf
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

