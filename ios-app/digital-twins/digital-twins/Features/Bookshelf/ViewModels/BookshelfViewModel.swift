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
    @Published var isEditMode = false
    
    // MARK: - Private Properties
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    private var pendingReorder: Task<Void, Never>?
    
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
    
    func fetchBookshelf() async {
        await loadBookshelf()
    }
    
    func addBookManually(title: String, author: String) async {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty,
              !author.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let response = try await apiService.addBook(
                title: title.trimmingCharacters(in: .whitespaces),
                author: author.trimmingCharacters(in: .whitespaces)
            )
            books = response.bookshelf.books
            
            if let lastUpdatedString = response.bookshelf.lastUpdated {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                lastUpdated = formatter.date(from: lastUpdatedString)
            }
            
            successMessage = "Added '\(title)'"
            showSuccess = true
            isServerReachable = true
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            handleError(.networkError(error.localizedDescription))
        }
        
        isLoading = false
    }
    
    func removeBook(_ book: Book) async {
        isLoading = true
        error = nil
        
        do {
            try await apiService.removeBook(title: book.title, author: book.author)
            // Remove from local array
            books.removeAll { $0.id == book.id }
            lastUpdated = Date()
            successMessage = "Removed '\(book.title)'"
            showSuccess = true
            isServerReachable = true
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            handleError(.networkError(error.localizedDescription))
        }
        
        isLoading = false
    }
    
    func openCamera() {
        showCamera = true
    }
    
    func toggleEditMode() {
        isEditMode.toggle()
    }
    
    func moveBook(from source: IndexSet, to destination: Int) {
        books.move(fromOffsets: source, toOffset: destination)
        
        // Update order values
        for (index, _) in books.enumerated() {
            books[index].order = index
        }
        
        // Debounce the API call
        pendingReorder?.cancel()
        pendingReorder = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second debounce
            if !Task.isCancelled {
                await persistBookOrder()
            }
        }
    }
    
    func moveBookDirectly(fromIndex: Int, toIndex: Int) {
        guard fromIndex != toIndex,
              fromIndex >= 0, fromIndex < books.count,
              toIndex >= 0, toIndex < books.count else { return }
        
        let book = books.remove(at: fromIndex)
        books.insert(book, at: toIndex)
        
        // Update order values
        for (index, _) in books.enumerated() {
            books[index].order = index
        }
        
        // Debounce the API call
        pendingReorder?.cancel()
        pendingReorder = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second debounce
            if !Task.isCancelled {
                await persistBookOrder()
            }
        }
    }
    
    private func persistBookOrder() async {
        do {
            try await apiService.reorderBooks(books)
            lastUpdated = Date()
            isServerReachable = true
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            handleError(.networkError(error.localizedDescription))
        }
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

