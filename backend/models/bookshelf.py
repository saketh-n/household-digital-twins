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
    order: int = 0  # Position in the bookshelf for ordering
    
    def book_key(self) -> tuple:
        """Unique key for deduplication (title + author)"""
        return (self.title.lower().strip(), self.author.lower().strip())


class Bookshelf(BaseModel):
    """Bookshelf digital twin model"""
    books: list[Book] = []
    last_updated: Optional[str] = None


class AuditSession(BaseModel):
    """Temporary audit session for comparing physical bookshelf with digital twin"""
    scanned_books: list[Book] = []  # Books found during audit scanning
    photos_taken: int = 0  # Number of photos processed
    started_at: Optional[str] = None
    last_scan_at: Optional[str] = None


class AuditDiff(BaseModel):
    """Difference between audit session and main bookshelf"""
    books_to_add: list[Book] = []  # Books in audit but not in main bookshelf
    books_to_remove: list[Book] = []  # Books in main bookshelf but not in audit
    books_matching: list[Book] = []  # Books present in both


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
        
        # Find the max order to append new books at the end
        max_order = max((b.order for b in bookshelf.books), default=-1)
        
        # Add or update books
        for book in books:
            key = (book.title.lower(), book.author.lower())
            if key not in existing_books:
                # New book - assign next order
                max_order += 1
                book = Book(
                    title=book.title,
                    author=book.author,
                    cover_url=book.cover_url,
                    order=max_order
                )
            existing_books[key] = book
        
        # Sort by order before saving
        bookshelf.books = sorted(existing_books.values(), key=lambda b: b.order)
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
        # Re-normalize order after removal
        for i, book in enumerate(bookshelf.books):
            bookshelf.books[i] = Book(
                title=book.title,
                author=book.author,
                cover_url=book.cover_url,
                order=i
            )
        bookshelf.last_updated = datetime.now().isoformat()
        self._save(bookshelf)
        return bookshelf
    
    def reorder_books(self, book_orders: list[dict]) -> Bookshelf:
        """
        Reorder books based on provided order mapping.
        book_orders: list of {"title": str, "author": str, "order": int}
        """
        bookshelf = self._load()
        
        # Create order lookup
        order_map = {
            (b["title"].lower(), b["author"].lower()): b["order"]
            for b in book_orders
        }
        
        # Update book orders
        updated_books = []
        for book in bookshelf.books:
            key = (book.title.lower(), book.author.lower())
            new_order = order_map.get(key, book.order)
            updated_books.append(Book(
                title=book.title,
                author=book.author,
                cover_url=book.cover_url,
                order=new_order
            ))
        
        # Sort by new order
        bookshelf.books = sorted(updated_books, key=lambda b: b.order)
        bookshelf.last_updated = datetime.now().isoformat()
        
        self._save(bookshelf)
        return bookshelf


class AuditSessionManager:
    """Manages the audit session for comparing physical and digital bookshelves"""
    
    def __init__(self, data_path: str = None):
        if data_path is None:
            data_path = Path(__file__).parent.parent / "data" / "audit_session.json"
        self.data_path = Path(data_path)
        self._ensure_data_file()
    
    def _ensure_data_file(self):
        """Ensure the data file exists"""
        if not self.data_path.exists():
            self.data_path.parent.mkdir(parents=True, exist_ok=True)
            self._save(AuditSession())
    
    def _load(self) -> AuditSession:
        """Load audit session from JSON file"""
        try:
            with open(self.data_path, 'r') as f:
                data = json.load(f)
            return AuditSession(**data)
        except (json.JSONDecodeError, FileNotFoundError):
            return AuditSession()
    
    def _save(self, session: AuditSession):
        """Save audit session to JSON file"""
        with open(self.data_path, 'w') as f:
            json.dump(session.model_dump(), f, indent=2)
    
    def get_session(self) -> AuditSession:
        """Get the current audit session"""
        return self._load()
    
    def start_session(self) -> AuditSession:
        """Start a new audit session, clearing any existing one"""
        session = AuditSession(
            scanned_books=[],
            photos_taken=0,
            started_at=datetime.now().isoformat(),
            last_scan_at=None
        )
        self._save(session)
        return session
    
    def add_scanned_books(self, books: list[Book]) -> AuditSession:
        """Add books from a scan to the audit session with deduplication"""
        session = self._load()
        
        # Start session if not started
        if session.started_at is None:
            session.started_at = datetime.now().isoformat()
        
        # Create map of existing scanned books for deduplication
        existing = {b.book_key(): b for b in session.scanned_books}
        
        # Add new books (deduplicated by title+author)
        for book in books:
            key = book.book_key()
            if key not in existing:
                existing[key] = book
            else:
                # Update cover_url if the new one has it and existing doesn't
                if book.cover_url and not existing[key].cover_url:
                    existing[key] = book
        
        session.scanned_books = list(existing.values())
        session.photos_taken += 1
        session.last_scan_at = datetime.now().isoformat()
        
        self._save(session)
        return session
    
    def add_manual_book(self, book: Book) -> AuditSession:
        """Manually add a book to the audit session"""
        session = self._load()
        
        if session.started_at is None:
            session.started_at = datetime.now().isoformat()
        
        # Deduplicate
        existing = {b.book_key(): b for b in session.scanned_books}
        existing[book.book_key()] = book
        
        session.scanned_books = list(existing.values())
        session.last_scan_at = datetime.now().isoformat()
        
        self._save(session)
        return session
    
    def remove_book_from_session(self, title: str, author: str) -> AuditSession:
        """Remove a book from the audit session"""
        session = self._load()
        key = (title.lower().strip(), author.lower().strip())
        session.scanned_books = [
            b for b in session.scanned_books if b.book_key() != key
        ]
        self._save(session)
        return session
    
    def compute_diff(self, main_bookshelf: Bookshelf) -> AuditDiff:
        """Compare audit session with main bookshelf and return diff"""
        session = self._load()
        
        # Create sets of book keys
        audit_keys = {b.book_key() for b in session.scanned_books}
        main_keys = {b.book_key() for b in main_bookshelf.books}
        
        # Books to add (in audit but not in main)
        to_add_keys = audit_keys - main_keys
        books_to_add = [b for b in session.scanned_books if b.book_key() in to_add_keys]
        
        # Books to remove (in main but not in audit)
        to_remove_keys = main_keys - audit_keys
        books_to_remove = [b for b in main_bookshelf.books if b.book_key() in to_remove_keys]
        
        # Books matching (in both)
        matching_keys = audit_keys & main_keys
        books_matching = [b for b in session.scanned_books if b.book_key() in matching_keys]
        
        return AuditDiff(
            books_to_add=books_to_add,
            books_to_remove=books_to_remove,
            books_matching=books_matching
        )
    
    def clear_session(self) -> AuditSession:
        """Clear the audit session"""
        session = AuditSession()
        self._save(session)
        return session

