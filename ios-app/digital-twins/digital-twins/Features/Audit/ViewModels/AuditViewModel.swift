//
//  AuditViewModel.swift
//  digital-twins
//
//  ViewModel for audit mode - comparing physical bookshelf with digital twin
//

import Foundation
import SwiftUI

@MainActor
class AuditViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var session: AuditSession = AuditSession()
    @Published var diff: AuditDiff?
    @Published var diffSummary: String = ""
    
    @Published var isLoading = false
    @Published var isScanning = false
    @Published var error: APIError?
    @Published var toastMessage: String?
    
    @Published var showDiffView = false
    @Published var showManualEntry = false
    @Published var showCamera = false
    
    // State
    enum AuditState {
        case idle           // Not started
        case scanning       // Taking photos
        case reviewing      // Reviewing diff
    }
    @Published var state: AuditState = .idle
    
    private let apiService = APIService.shared
    
    // MARK: - Session Management
    
    func startAudit() async {
        isLoading = true
        error = nil
        
        do {
            session = try await apiService.startAudit()
            state = .scanning
            toastMessage = "Audit started! Take photos of your bookshelf"
        } catch let apiError as APIError {
            error = apiError
        } catch {
            self.error = .networkError(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func loadExistingSession() async {
        isLoading = true
        
        do {
            let response = try await apiService.getAuditSession()
            session = response.session
            
            // Check if there's an active session
            if session.startedAt != nil && !session.scannedBooks.isEmpty {
                state = .scanning
            }
        } catch {
            // No active session, that's fine
            state = .idle
        }
        
        isLoading = false
    }
    
    func cancelAudit() async {
        isLoading = true
        
        do {
            try await apiService.clearAudit()
            session = AuditSession()
            state = .idle
            diff = nil
            diffSummary = ""
            toastMessage = "Audit cancelled"
        } catch let apiError as APIError {
            error = apiError
        } catch {
            self.error = .networkError(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    // MARK: - Scanning
    
    func scanImage(_ image: UIImage) async {
        isScanning = true
        error = nil
        
        do {
            let response = try await apiService.auditScan(image: image)
            session = response.session
            
            if response.newBooksAdded > 0 {
                toastMessage = "Found \(response.newBooksAdded) new book(s)!"
            } else if response.booksDetected > 0 {
                toastMessage = "All \(response.booksDetected) book(s) already scanned"
            } else {
                toastMessage = "No books detected in this photo"
            }
        } catch let apiError as APIError {
            error = apiError
        } catch {
            self.error = .networkError(error.localizedDescription)
        }
        
        isScanning = false
    }
    
    // MARK: - Manual Entry
    
    func addManualBook(title: String, author: String) async {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty,
              !author.trimmingCharacters(in: .whitespaces).isEmpty else {
            toastMessage = "Please enter both title and author"
            return
        }
        
        isLoading = true
        
        do {
            session = try await apiService.auditAddBook(title: title.trimmingCharacters(in: .whitespaces),
                                                         author: author.trimmingCharacters(in: .whitespaces))
            toastMessage = "Added '\(title)' to audit"
            showManualEntry = false
        } catch let apiError as APIError {
            error = apiError
        } catch {
            self.error = .networkError(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func removeBookFromSession(_ book: Book) async {
        isLoading = true
        
        do {
            session = try await apiService.auditRemoveBook(title: book.title, author: book.author)
            toastMessage = "Removed '\(book.title)'"
        } catch let apiError as APIError {
            error = apiError
        } catch {
            self.error = .networkError(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    // MARK: - Diff & Apply
    
    func finishScanning() async {
        guard !session.scannedBooks.isEmpty else {
            toastMessage = "No books scanned yet. Take some photos first!"
            return
        }
        
        isLoading = true
        
        do {
            let response = try await apiService.getAuditDiff()
            diff = response.diff
            diffSummary = response.summary
            state = .reviewing
            showDiffView = true
        } catch let apiError as APIError {
            error = apiError
        } catch {
            self.error = .networkError(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func applyChanges(addNew: Bool, removeMissing: Bool) async -> Bool {
        isLoading = true
        
        do {
            _ = try await apiService.applyAuditDiff(addNewBooks: addNew, removeMissingBooks: removeMissing)
            session = AuditSession()
            diff = nil
            state = .idle
            showDiffView = false
            toastMessage = "Changes applied successfully!"
            isLoading = false
            return true
        } catch let apiError as APIError {
            error = apiError
            isLoading = false
            return false
        } catch {
            self.error = .networkError(error.localizedDescription)
            isLoading = false
            return false
        }
    }
    
    func discardChanges() async {
        await cancelAudit()
        showDiffView = false
    }
    
    // MARK: - Helpers
    
    func dismissError() {
        error = nil
    }
    
    func dismissToast() {
        toastMessage = nil
    }
}

