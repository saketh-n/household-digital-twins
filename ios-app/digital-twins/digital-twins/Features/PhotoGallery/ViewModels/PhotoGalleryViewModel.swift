//
//  PhotoGalleryViewModel.swift
//  digital-twins
//
//  ViewModel for managing a gallery of photos to be processed
//

import Foundation
import SwiftUI
import UIKit

@MainActor
class PhotoGalleryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var photos: [CapturedPhoto] = []
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0
    @Published var currentPhotoIndex: Int = 0
    @Published var error: APIError?
    @Published var showCamera = false
    @Published var toastMessage: String?
    
    // Results after processing
    @Published var detectedBooks: [Book] = []
    @Published var processingComplete = false
    
    private let apiService = APIService.shared
    
    // MARK: - Photo Management
    
    func addPhoto(_ image: UIImage) {
        let photo = CapturedPhoto(image: image)
        photos.append(photo)
        toastMessage = "Photo added (\(photos.count) total)"
    }
    
    func removePhoto(at index: Int) {
        guard index >= 0 && index < photos.count else { return }
        photos.remove(at: index)
    }
    
    func removePhoto(_ photo: CapturedPhoto) {
        photos.removeAll { $0.id == photo.id }
    }
    
    func clearPhotos() {
        photos.removeAll()
        detectedBooks.removeAll()
        processingComplete = false
    }
    
    // MARK: - Batch Processing (Regular Scan - adds to main bookshelf)
    
    func processAllPhotos() async {
        guard !photos.isEmpty else {
            toastMessage = "No photos to process"
            return
        }
        
        isProcessing = true
        processingProgress = 0
        currentPhotoIndex = 0
        detectedBooks.removeAll()
        
        // Track unique books by title+author
        var uniqueBooks: [String: Book] = [:]
        
        for (index, photo) in photos.enumerated() {
            currentPhotoIndex = index + 1
            processingProgress = Double(index) / Double(photos.count)
            
            do {
                let response = try await apiService.scanBookshelf(image: photo.image)
                
                // Add to unique books (deduplicate)
                for book in response.bookshelf.books {
                    let key = "\(book.title.lowercased())|\(book.author.lowercased())"
                    if uniqueBooks[key] == nil {
                        uniqueBooks[key] = book
                    }
                }
                
                // Mark photo as processed
                if let photoIndex = photos.firstIndex(where: { $0.id == photo.id }) {
                    photos[photoIndex].isProcessed = true
                    photos[photoIndex].booksFound = response.booksDetected
                }
                
            } catch let apiError as APIError {
                // Mark photo as failed but continue with others
                if let photoIndex = photos.firstIndex(where: { $0.id == photo.id }) {
                    photos[photoIndex].processingFailed = true
                }
                print("Failed to process photo \(index + 1): \(apiError.localizedDescription)")
            } catch {
                if let photoIndex = photos.firstIndex(where: { $0.id == photo.id }) {
                    photos[photoIndex].processingFailed = true
                }
            }
        }
        
        processingProgress = 1.0
        detectedBooks = Array(uniqueBooks.values)
        processingComplete = true
        isProcessing = false
        
        let totalBooks = detectedBooks.count
        toastMessage = "Found \(totalBooks) unique book\(totalBooks == 1 ? "" : "s") from \(photos.count) photo\(photos.count == 1 ? "" : "s")"
    }
    
    // MARK: - Batch Processing (Audit Mode - adds to audit session)
    
    func processAllPhotosForAudit() async {
        guard !photos.isEmpty else {
            toastMessage = "No photos to process"
            return
        }
        
        isProcessing = true
        processingProgress = 0
        currentPhotoIndex = 0
        detectedBooks.removeAll()
        
        for (index, photo) in photos.enumerated() {
            currentPhotoIndex = index + 1
            processingProgress = Double(index) / Double(photos.count)
            
            do {
                let response = try await apiService.auditScan(image: photo.image)
                
                // Mark photo as processed
                if let photoIndex = photos.firstIndex(where: { $0.id == photo.id }) {
                    photos[photoIndex].isProcessed = true
                    photos[photoIndex].booksFound = response.booksDetected
                }
                
            } catch let apiError as APIError {
                if let photoIndex = photos.firstIndex(where: { $0.id == photo.id }) {
                    photos[photoIndex].processingFailed = true
                }
                print("Failed to process photo \(index + 1): \(apiError.localizedDescription)")
            } catch {
                if let photoIndex = photos.firstIndex(where: { $0.id == photo.id }) {
                    photos[photoIndex].processingFailed = true
                }
            }
        }
        
        // Fetch the final audit session to get all unique books
        do {
            let sessionResponse = try await apiService.getAuditSession()
            detectedBooks = sessionResponse.session.scannedBooks
        } catch {
            print("Failed to fetch audit session: \(error)")
        }
        
        processingProgress = 1.0
        processingComplete = true
        isProcessing = false
        
        let totalBooks = detectedBooks.count
        toastMessage = "Found \(totalBooks) unique book\(totalBooks == 1 ? "" : "s") from \(photos.count) photo\(photos.count == 1 ? "" : "s")"
    }
    
    // MARK: - Helpers
    
    func dismissToast() {
        toastMessage = nil
    }
    
    func dismissError() {
        error = nil
    }
}

// MARK: - Captured Photo Model
struct CapturedPhoto: Identifiable {
    let id = UUID()
    let image: UIImage
    let capturedAt: Date = Date()
    var isProcessed: Bool = false
    var processingFailed: Bool = false
    var booksFound: Int = 0
}

