"""
Bookshelf Digital Twin Model
Manages the state of the bookshelf including books with their metadata
"""
import json
from datetime import datetime
from pathlib import Path
from typing import Optional
from pydantic import BaseModel


class Book(BaseModel):
    """Individual book model"""
    title: str
    author: str
    cover_url: Optional[str] = None


class Bookshelf(BaseModel):
    """Bookshelf digital twin model"""
    books: list[Book] = []
    last_updated: Optional[str] = None


class BookshelfManager:
    """Manages persistence and operations on the bookshelf digital twin"""
    
    def __init__(self, data_path: str = None):
        if data_path is None:
            data_path = Path(__file__).parent.parent / "data" / "bookshelf.json"
        self.data_path = Path(data_path)
        self._ensure_data_file()
    
    def _ensure_data_file(self):
        """Ensure the data file exists"""
        if not self.data_path.exists():
            self.data_path.parent.mkdir(parents=True, exist_ok=True)
            self._save(Bookshelf())
    
    def _load(self) -> Bookshelf:
        """Load bookshelf from JSON file"""
        with open(self.data_path, 'r') as f:
            data = json.load(f)
        return Bookshelf(**data)
    
    def _save(self, bookshelf: Bookshelf):
        """Save bookshelf to JSON file"""
        with open(self.data_path, 'w') as f:
            json.dump(bookshelf.model_dump(), f, indent=2)
    
    def get_bookshelf(self) -> Bookshelf:
        """Get the current bookshelf state"""
        return self._load()
    
    def add_books(self, books: list[Book]) -> Bookshelf:
        """Add books to the bookshelf (updates existing, adds new)"""
        bookshelf = self._load()
        
        # Create a map of existing books by title+author for deduplication
        existing_books = {
            (b.title.lower(), b.author.lower()): b 
            for b in bookshelf.books
        }
        
        # Add or update books
        for book in books:
            key = (book.title.lower(), book.author.lower())
            existing_books[key] = book
        
        bookshelf.books = list(existing_books.values())
        bookshelf.last_updated = datetime.now().isoformat()
        
        self._save(bookshelf)
        return bookshelf
    
    def clear_bookshelf(self) -> Bookshelf:
        """Clear all books from the bookshelf"""
        bookshelf = Bookshelf(
            books=[],
            last_updated=datetime.now().isoformat()
        )
        self._save(bookshelf)
        return bookshelf
    
    def remove_book(self, title: str, author: str) -> Bookshelf:
        """Remove a specific book from the bookshelf"""
        bookshelf = self._load()
        bookshelf.books = [
            b for b in bookshelf.books 
            if not (b.title.lower() == title.lower() and b.author.lower() == author.lower())
        ]
        bookshelf.last_updated = datetime.now().isoformat()
        self._save(bookshelf)
        return bookshelf

