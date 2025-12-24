//
//  BookshelfViewModel.swift
//  digital-twins
//
//  ViewModel for bookshelf management
//

import Foundation
import SwiftUI
import Combine

@MainActor
class BookshelfViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var books: [Book] = []
    @Published var isLoading = false
    @Published var isScanning = false
    @Published var error: APIError?
    @Published var showError = false
    @Published var showCamera = false
    @Published var showSuccess = false
    @Published var successMessage = ""
    @Published var lastUpdated: Date?
    @Published var isServerReachable = true
    
    // MARK: - Private Properties
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var totalBooks: Int { books.count }
    
    var hasBooks: Bool { !books.isEmpty }
    
    var formattedLastUpdated: String? {
        guard let date = lastUpdated else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // MARK: - Initialization
    init() {
        // Load bookshelf on init
        Task {
            await loadBookshelf()
        }
    }
    
    // MARK: - Public Methods
    func loadBookshelf() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            let response = try await apiService.fetchBookshelf()
            books = response.bookshelf.books
            
            if let lastUpdatedString = response.bookshelf.lastUpdated {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                lastUpdated = formatter.date(from: lastUpdatedString)
            }
            
            isServerReachable = true
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            handleError(.networkError(error.localizedDescription))
        }
        
        isLoading = false
    }
    
    func scanImage(_ image: UIImage) async {
        guard !isScanning else { return }
        
        isScanning = true
        error = nil
        showCamera = false
        
        do {
            let response = try await apiService.scanBookshelf(image: image)
            books = response.bookshelf.books
            
            if let lastUpdatedString = response.bookshelf.lastUpdated {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                lastUpdated = formatter.date(from: lastUpdatedString)
            }
            
            // Show success message
            if response.booksDetected > 0 {
                successMessage = "Found \(response.booksDetected) book\(response.booksDetected == 1 ? "" : "s")!"
            } else {
                successMessage = "No books detected in the image"
            }
            showSuccess = true
            
            isServerReachable = true
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            handleError(.networkError(error.localizedDescription))
        }
        
        isScanning = false
    }
    
    func clearBookshelf() async {
        isLoading = true
        error = nil
        
        do {
            try await apiService.clearBookshelf()
            books = []
            lastUpdated = Date()
            successMessage = "Bookshelf cleared"
            showSuccess = true
            isServerReachable = true
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            handleError(.networkError(error.localizedDescription))
        }
        
        isLoading = false
    }
    
    func refresh() async {
        await loadBookshelf()
    }
    
    func openCamera() {
        showCamera = true
    }
    
    func dismissError() {
        showError = false
        error = nil
    }
    
    func retryLastAction() {
        Task {
            await loadBookshelf()
        }
    }
    
    // MARK: - Private Methods
    private func handleError(_ apiError: APIError) {
        error = apiError
        showError = true
        
        switch apiError {
        case .serverUnreachable, .timeout:
            isServerReachable = false
        default:
            break
        }
    }
}

