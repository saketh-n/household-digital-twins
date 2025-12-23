"""
OpenLibrary Service
Fetches book cover images from OpenLibrary API
"""
import httpx
from typing import Optional
from urllib.parse import quote


async def get_book_cover_url(title: str, author: str) -> Optional[str]:
    """
    Search OpenLibrary for a book and return its cover URL
    
    Args:
        title: Book title
        author: Author name
    
    Returns:
        URL to book cover image, or None if not found
    """
    # Search for the book
    search_query = f"{title} {author}"
    encoded_query = quote(search_query)
    
    search_url = f"https://openlibrary.org/search.json?q={encoded_query}&limit=1"
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(search_url, timeout=10.0)
            response.raise_for_status()
            data = response.json()
            
            if data.get("docs") and len(data["docs"]) > 0:
                doc = data["docs"][0]
                
                # Try to get cover from cover_i (cover ID)
                cover_id = doc.get("cover_i")
                if cover_id:
                    # OpenLibrary cover URL format
                    # Size options: S (small), M (medium), L (large)
                    return f"https://covers.openlibrary.org/b/id/{cover_id}-M.jpg"
                
                # Fallback: try ISBN-based cover
                isbns = doc.get("isbn", [])
                if isbns:
                    isbn = isbns[0]
                    return f"https://covers.openlibrary.org/b/isbn/{isbn}-M.jpg"
            
            return None
            
        except (httpx.HTTPError, KeyError, IndexError) as e:
            print(f"Error fetching cover for '{title}' by '{author}': {e}")
            return None


async def enrich_books_with_covers(books: list[dict]) -> list[dict]:
    """
    Enrich a list of books with cover URLs
    
    Args:
        books: List of books with 'title' and 'author' keys
    
    Returns:
        Same list with 'cover_url' added to each book
    """
    enriched_books = []
    
    for book in books:
        cover_url = await get_book_cover_url(book["title"], book["author"])
        enriched_books.append({
            "title": book["title"],
            "author": book["author"],
            "cover_url": cover_url
        })
    
    return enriched_books

