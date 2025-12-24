//
//  Models.swift
//  digital-twins
//
//  Data models matching backend API
//

import Foundation

// MARK: - Book Model
struct Book: Codable, Identifiable, Equatable {
    let title: String
    let author: String
    let coverUrl: String?
    
    var id: String { "\(title)-\(author)" }
    
    enum CodingKeys: String, CodingKey {
        case title
        case author
        case coverUrl = "cover_url"
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

