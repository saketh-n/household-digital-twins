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

from models import Book, Bookshelf, BookshelfManager, AuditSession, AuditDiff, AuditSessionManager
from services import detect_books_in_image, enrich_books_with_covers, get_book_cover_url


# Initialize managers
bookshelf_manager = BookshelfManager()
audit_manager = AuditSessionManager()


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


class BookOrderItem(BaseModel):
    """Single book order item"""
    title: str
    author: str
    order: int


class ReorderBooksRequest(BaseModel):
    """Request to reorder books"""
    book_orders: list[BookOrderItem]


@app.put("/bookshelf/reorder")
async def reorder_books(request: ReorderBooksRequest):
    """
    Reorder books in the bookshelf
    
    Provide a list of books with their new order positions
    """
    book_orders = [
        {"title": b.title, "author": b.author, "order": b.order}
        for b in request.book_orders
    ]
    bookshelf = bookshelf_manager.reorder_books(book_orders)
    return {
        "message": "Books reordered successfully",
        "bookshelf": bookshelf
    }


@app.post("/bookshelf/book")
async def add_book(request: AddBookRequest):
    """
    Manually add a book to the bookshelf
    
    Optionally fetches cover from OpenLibrary if not provided
    """
    cover_url = request.cover_url
    
    # Fetch cover if not provided
    if not cover_url:
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


# ============================================================================
# Audit Mode Endpoints
# ============================================================================

class AuditSessionResponse(BaseModel):
    """Response containing audit session data"""
    session: AuditSession
    total_scanned: int


class AuditDiffResponse(BaseModel):
    """Response containing audit diff"""
    diff: AuditDiff
    summary: str


class AuditScanResponse(BaseModel):
    """Response from scanning during audit"""
    message: str
    books_detected: int
    new_books_added: int  # Books added that weren't already in session
    session: AuditSession


@app.post("/audit/start")
async def start_audit():
    """
    Start a new audit session
    
    Clears any existing audit session and starts fresh
    """
    session = audit_manager.start_session()
    return {
        "message": "Audit session started",
        "session": session
    }


@app.get("/audit", response_model=AuditSessionResponse)
async def get_audit_session():
    """
    Get the current audit session
    
    Returns all scanned books and session info
    """
    session = audit_manager.get_session()
    return AuditSessionResponse(
        session=session,
        total_scanned=len(session.scanned_books)
    )


@app.post("/audit/scan", response_model=AuditScanResponse)
async def audit_scan(image: UploadFile = File(...)):
    """
    Scan an image during audit mode
    
    Books are accumulated in the audit session, deduplicated by title+author
    """
    allowed_types = ["image/jpeg", "image/png", "image/gif", "image/webp"]
    if image.content_type not in allowed_types:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type. Allowed types: {', '.join(allowed_types)}"
        )
    
    if not os.getenv("ANTHROPIC_API_KEY"):
        raise HTTPException(
            status_code=503,
            detail="Anthropic API key not configured. Cannot process images."
        )
    
    image_data = await image.read()
    
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
        session = audit_manager.get_session()
        return AuditScanResponse(
            message="No books detected in the image",
            books_detected=0,
            new_books_added=0,
            session=session
        )
    
    # Enrich books with cover URLs
    books_data = [{"title": b.title, "author": b.author} for b in detection_result.books]
    enriched_books = await enrich_books_with_covers(books_data)
    
    # Convert to Book models
    detected_books = [
        Book(title=b["title"], author=b["author"], cover_url=b["cover_url"])
        for b in enriched_books
    ]
    
    # Get count before adding
    session_before = audit_manager.get_session()
    count_before = len(session_before.scanned_books)
    
    # Add to audit session (with deduplication)
    session = audit_manager.add_scanned_books(detected_books)
    new_books_added = len(session.scanned_books) - count_before
    
    return AuditScanResponse(
        message=f"Detected {len(detected_books)} books, {new_books_added} new",
        books_detected=len(detected_books),
        new_books_added=new_books_added,
        session=session
    )


@app.post("/audit/book")
async def audit_add_manual_book(request: AddBookRequest):
    """
    Manually add a book to the audit session
    
    Use this when the scanner missed a book
    """
    cover_url = request.cover_url
    if not cover_url:
        cover_url = await get_book_cover_url(request.title, request.author)
    
    book = Book(
        title=request.title,
        author=request.author,
        cover_url=cover_url
    )
    
    session = audit_manager.add_manual_book(book)
    
    return {
        "message": f"Added '{request.title}' to audit session",
        "book": book,
        "session": session
    }


@app.delete("/audit/book")
async def audit_remove_book(request: RemoveBookRequest):
    """
    Remove a book from the audit session
    """
    session = audit_manager.remove_book_from_session(request.title, request.author)
    return {
        "message": f"Removed '{request.title}' from audit session",
        "session": session
    }


@app.get("/audit/diff", response_model=AuditDiffResponse)
async def get_audit_diff():
    """
    Compare audit session with main bookshelf
    
    Returns books to add, books to remove, and matching books
    """
    bookshelf = bookshelf_manager.get_bookshelf()
    diff = audit_manager.compute_diff(bookshelf)
    
    summary_parts = []
    if diff.books_to_add:
        summary_parts.append(f"{len(diff.books_to_add)} new book(s) to add")
    if diff.books_to_remove:
        summary_parts.append(f"{len(diff.books_to_remove)} book(s) missing from shelf")
    if diff.books_matching:
        summary_parts.append(f"{len(diff.books_matching)} book(s) matching")
    
    summary = ", ".join(summary_parts) if summary_parts else "No differences found"
    
    return AuditDiffResponse(
        diff=diff,
        summary=summary
    )


class ApplyDiffRequest(BaseModel):
    """Request to apply audit diff"""
    add_new_books: bool = True  # Add books found in audit but not in bookshelf
    remove_missing_books: bool = False  # Remove books not found in audit


@app.post("/audit/apply")
async def apply_audit_diff(request: ApplyDiffRequest):
    """
    Apply the audit diff to the main bookshelf
    
    Can choose to add new books and/or remove missing books
    """
    bookshelf = bookshelf_manager.get_bookshelf()
    diff = audit_manager.compute_diff(bookshelf)
    
    added_count = 0
    removed_count = 0
    
    # Add new books
    if request.add_new_books and diff.books_to_add:
        bookshelf_manager.add_books(diff.books_to_add)
        added_count = len(diff.books_to_add)
    
    # Remove missing books
    if request.remove_missing_books and diff.books_to_remove:
        for book in diff.books_to_remove:
            bookshelf_manager.remove_book(book.title, book.author)
            removed_count += 1
    
    # Clear audit session
    audit_manager.clear_session()
    
    # Get updated bookshelf
    updated_bookshelf = bookshelf_manager.get_bookshelf()
    
    return {
        "message": f"Applied audit: {added_count} added, {removed_count} removed",
        "books_added": added_count,
        "books_removed": removed_count,
        "bookshelf": updated_bookshelf
    }


@app.delete("/audit")
async def clear_audit():
    """
    Clear the audit session without applying changes
    """
    session = audit_manager.clear_session()
    return {
        "message": "Audit session cleared",
        "session": session
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

