//
//  Models.swift
//  digital-twins
//
//  Data models matching backend API
//

import Foundation

// MARK: - Book Model
struct Book: Codable, Identifiable, Equatable, Hashable {
    let title: String
    let author: String
    let coverUrl: String?
    var order: Int
    
    var id: String { "\(title)-\(author)" }
    
    enum CodingKeys: String, CodingKey {
        case title
        case author
        case coverUrl = "cover_url"
        case order
    }
    
    init(title: String, author: String, coverUrl: String?, order: Int = 0) {
        self.title = title
        self.author = author
        self.coverUrl = coverUrl
        self.order = order
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        author = try container.decode(String.self, forKey: .author)
        coverUrl = try container.decodeIfPresent(String.self, forKey: .coverUrl)
        order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0
    }
}

// MARK: - Book Order Item (for reordering API)
struct BookOrderItem: Codable {
    let title: String
    let author: String
    let order: Int
}

struct ReorderBooksRequest: Codable {
    let bookOrders: [BookOrderItem]
    
    enum CodingKeys: String, CodingKey {
        case bookOrders = "book_orders"
    }
}

// MARK: - Bookshelf Model
struct Bookshelf: Codable {
    let books: [Book]
    let lastUpdated: String?
    
    enum CodingKeys: String, CodingKey {
        case books
        case lastUpdated = "last_updated"
    }
}

// MARK: - API Response Models
struct BookshelfResponse: Codable {
    let bookshelf: Bookshelf
    let totalBooks: Int
    
    enum CodingKeys: String, CodingKey {
        case bookshelf
        case totalBooks = "total_books"
    }
}

struct ScanResponse: Codable {
    let message: String
    let booksDetected: Int
    let booksAdded: Int
    let bookshelf: Bookshelf
    
    enum CodingKeys: String, CodingKey {
        case message
        case booksDetected = "books_detected"
        case booksAdded = "books_added"
        case bookshelf
    }
}

struct HealthResponse: Codable {
    let status: String
    let anthropicConfigured: Bool
    
    enum CodingKeys: String, CodingKey {
        case status
        case anthropicConfigured = "anthropic_configured"
    }
}

// MARK: - Audit Session Models
struct AuditSession: Codable {
    var scannedBooks: [Book]
    var photosTaken: Int
    var startedAt: String?
    var lastScanAt: String?
    
    enum CodingKeys: String, CodingKey {
        case scannedBooks = "scanned_books"
        case photosTaken = "photos_taken"
        case startedAt = "started_at"
        case lastScanAt = "last_scan_at"
    }
    
    init(scannedBooks: [Book] = [], photosTaken: Int = 0, startedAt: String? = nil, lastScanAt: String? = nil) {
        self.scannedBooks = scannedBooks
        self.photosTaken = photosTaken
        self.startedAt = startedAt
        self.lastScanAt = lastScanAt
    }
}

struct AuditDiff: Codable {
    let booksToAdd: [Book]
    let booksToRemove: [Book]
    let booksMatching: [Book]
    
    enum CodingKeys: String, CodingKey {
        case booksToAdd = "books_to_add"
        case booksToRemove = "books_to_remove"
        case booksMatching = "books_matching"
    }
}

struct AuditSessionResponse: Codable {
    let session: AuditSession
    let totalScanned: Int
    
    enum CodingKeys: String, CodingKey {
        case session
        case totalScanned = "total_scanned"
    }
}

struct AuditScanResponse: Codable {
    let message: String
    let booksDetected: Int
    let newBooksAdded: Int
    let session: AuditSession
    
    enum CodingKeys: String, CodingKey {
        case message
        case booksDetected = "books_detected"
        case newBooksAdded = "new_books_added"
        case session
    }
}

struct AuditDiffResponse: Codable {
    let diff: AuditDiff
    let summary: String
}

struct ApplyDiffRequest: Codable {
    let addNewBooks: Bool
    let removeMissingBooks: Bool
    
    enum CodingKeys: String, CodingKey {
        case addNewBooks = "add_new_books"
        case removeMissingBooks = "remove_missing_books"
    }
}

struct AddBookRequest: Codable {
    let title: String
    let author: String
    let coverUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case title
        case author
        case coverUrl = "cover_url"
    }
}

// MARK: - Error Types
enum APIError: LocalizedError {
    case networkError(String)
    case serverError(Int, String)
    case decodingError(String)
    case invalidURL
    case noData
    case timeout
    case serverUnreachable
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .decodingError(let message):
            return "Failed to parse response: \(message)"
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received from server"
        case .timeout:
            return "Request timed out. Please check your connection."
        case .serverUnreachable:
            return "Cannot connect to server. Make sure you're on the same network."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError, .timeout, .serverUnreachable:
            return "Check your WiFi connection and try again."
        case .serverError:
            return "The server encountered an error. Please try again later."
        default:
            return nil
        }
    }
}

