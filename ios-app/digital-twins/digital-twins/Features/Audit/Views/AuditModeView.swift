//
//  AuditModeView.swift
//  digital-twins
//
//  Main view for audit mode - gallery-based scanning to compare with digital twin
//

import SwiftUI
import UIKit

struct AuditModeView: View {
    @StateObject private var viewModel = AuditViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showPhotoGallery = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Main content based on state
                    switch viewModel.state {
                    case .idle:
                        startAuditView
                    case .scanning:
                        scanResultsView
                    case .reviewing:
                        EmptyView() // Handled by sheet
                    }
                }
            }
            .navigationTitle("Auditor Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                if viewModel.state == .scanning {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            Task {
                                await viewModel.cancelAudit()
                            }
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .fullScreenCover(isPresented: $showPhotoGallery) {
                PhotoGalleryView(mode: .audit) { books in
                    // After processing, load the session and show results
                    Task {
                        await viewModel.loadExistingSession()
                        if !viewModel.session.scannedBooks.isEmpty {
                            viewModel.state = .scanning
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showManualEntry) {
                ManualBookEntrySheet { title, author in
                    Task {
                        await viewModel.addManualBook(title: title, author: author)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showDiffView) {
                if let diff = viewModel.diff {
                    AuditDiffView(
                        diff: diff,
                        summary: viewModel.diffSummary,
                        onApply: { addNew, removeMissing in
                            Task {
                                let success = await viewModel.applyChanges(addNew: addNew, removeMissing: removeMissing)
                                if success {
                                    dismiss()
                                }
                            }
                        },
                        onDiscard: {
                            Task {
                                await viewModel.discardChanges()
                            }
                        }
                    )
                }
            }
            .overlay {
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
            .overlay(alignment: .top) {
                if let toast = viewModel.toastMessage {
                    ToastView(message: toast)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation {
                                    viewModel.dismissToast()
                                }
                            }
                        }
                }
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.dismissError() } }
            )) {
                Button("OK") { viewModel.dismissError() }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
            .task {
                await viewModel.loadExistingSession()
                // If there's an existing session with books, show results view
                if !viewModel.session.scannedBooks.isEmpty {
                    viewModel.state = .scanning
                }
            }
        }
    }
    
    // MARK: - Start Audit View
    private var startAuditView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            Image(systemName: "checkmark.shield")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "00d4aa"), Color(hex: "00b894")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            VStack(spacing: 12) {
                Text("Audit Your Bookshelf")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Take multiple photos of your bookshelf,\nreview them, then process all at once.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            // How it works
            VStack(alignment: .leading, spacing: 16) {
                auditStep(number: 1, icon: "photo.stack", text: "Take photos of all shelf sections")
                auditStep(number: 2, icon: "wand.and.stars", text: "Process all photos at once")
                auditStep(number: 3, icon: "plus.rectangle.on.rectangle", text: "Add any missed books manually")
                auditStep(number: 4, icon: "arrow.left.arrow.right", text: "Compare & sync with digital twin")
            }
            .padding(24)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .padding(.horizontal)
            
            Spacer()
            
            Button {
                Task {
                    await viewModel.startAudit()
                    showPhotoGallery = true
                }
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Start Audit")
                }
                .font(.headline)
                .foregroundColor(Color(hex: "1a1a2e"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "00d4aa"))
                .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
    
    private func auditStep(number: Int, icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: "00d4aa").opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "00d4aa"))
            }
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
        }
    }
    
    // MARK: - Scan Results View (after photos are processed)
    private var scanResultsView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.session.scannedBooks.count) books found")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("\(viewModel.session.photosTaken) photos processed")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button {
                    Task {
                        await viewModel.finishScanning()
                    }
                } label: {
                    Text("Compare")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color(hex: "1a1a2e"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(hex: "00d4aa"))
                        .cornerRadius(8)
                }
                .disabled(viewModel.session.scannedBooks.isEmpty)
                .opacity(viewModel.session.scannedBooks.isEmpty ? 0.5 : 1)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            
            // Book list
            if viewModel.session.scannedBooks.isEmpty {
                emptyResultsView
            } else {
                scannedBooksList
            }
            
            // Bottom actions
            bottomActions
        }
    }
    
    private var emptyResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "questionmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No books found")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Try adding more photos or add books manually")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.7))
            
            Spacer()
        }
    }
    
    private var scannedBooksList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.session.scannedBooks) { book in
                    scannedBookRow(book)
                }
            }
            .padding()
        }
    }
    
    private func scannedBookRow(_ book: Book) -> some View {
        HStack(spacing: 12) {
            // Cover thumbnail
            AsyncImage(url: URL(string: book.coverUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        Image(systemName: "book.closed")
                            .foregroundColor(.gray)
                    }
            }
            .frame(width: 40, height: 55)
            .cornerRadius(4)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(book.author)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Remove button
            Button {
                Task {
                    await viewModel.removeBookFromSession(book)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                    .font(.title3)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
    
    private var bottomActions: some View {
        HStack(spacing: 16) {
            // Add more photos
            Button {
                showPhotoGallery = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "photo.stack.fill")
                        .font(.title2)
                    Text("Add Photos")
                        .font(.caption2)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Add manually
            Button {
                viewModel.showManualEntry = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "plus.rectangle.on.rectangle")
                        .font(.title2)
                    Text("Add Book")
                        .font(.caption2)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(hex: "1a1a2e").opacity(0.95))
    }
    
    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                Text("Loading...")
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(Color(hex: "1a1a2e"))
            .cornerRadius(16)
        }
    }
}

// MARK: - Toast View
struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.subheadline.weight(.medium))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(hex: "00d4aa"))
            .cornerRadius(25)
            .shadow(radius: 10)
            .padding(.top, 8)
    }
}

#Preview {
    AuditModeView()
}
