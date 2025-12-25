//
//  BookshelfView.swift
//  digital-twins
//
//  Main bookshelf display view with 3D wooden bookshelf
//

import SwiftUI

struct BookshelfView: View {
    @ObservedObject var viewModel: BookshelfViewModel
    
    @State private var showClearConfirmation = false
    @State private var selectedBook: Book?
    @State private var showBookDetail = false
    @State private var showAuditMode = false
    @State private var showManualEntry = false
    @State private var showPhotoGallery = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background - warm room ambiance
                backgroundGradient
                
                // Main content
                if viewModel.isLoading && viewModel.books.isEmpty {
                    loadingView
                } else if viewModel.books.isEmpty && !viewModel.showError {
                    EmptyStateView(onScan: { showPhotoGallery = true })
                } else {
                    bookshelfContent
                }
                
                // Error banner overlay
                if viewModel.showError, let error = viewModel.error {
                    VStack {
                        Spacer()
                        ErrorBannerView(
                            error: error,
                            onRetry: viewModel.retryLastAction,
                            onDismiss: viewModel.dismissError
                        )
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .animation(.spring(response: 0.4), value: viewModel.showError)
                }
                
                // Scanning overlay
                if viewModel.isScanning {
                    LoadingOverlayView(message: "Analyzing your books...")
                        .transition(.opacity)
                }
            }
            .navigationTitle("My Bookshelf")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        // Audit mode button
                        Button {
                            showAuditMode = true
                        } label: {
                            Label("Auditor Mode", systemImage: "checkmark.shield")
                        }
                        
                        // Add book manually
                        Button {
                            showManualEntry = true
                        } label: {
                            Label("Add Book Manually", systemImage: "plus.rectangle.on.rectangle")
                        }
                        
                        if viewModel.hasBooks {
                            Divider()
                            
                            Button(action: viewModel.toggleEditMode) {
                                Label(
                                    viewModel.isEditMode ? "Done Arranging" : "Arrange Books",
                                    systemImage: viewModel.isEditMode ? "checkmark.circle" : "arrow.up.arrow.down"
                                )
                            }
                            
                            Divider()
                            
                            Button(role: .destructive, action: { showClearConfirmation = true }) {
                                Label("Clear All Books", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        if viewModel.hasBooks {
                            Button(action: viewModel.toggleEditMode) {
                                Text(viewModel.isEditMode ? "Done" : "Edit")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(viewModel.isEditMode ? .green : .brown)
                            }
                        }
                        
                        Button {
                            showPhotoGallery = true
                        } label: {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .brown],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showPhotoGallery) {
                PhotoGalleryView(mode: .regularScan) { books in
                    // Refresh bookshelf after scanning
                    Task {
                        await viewModel.fetchBookshelf()
                    }
                }
            }
            .sheet(isPresented: $showBookDetail) {
                if let book = selectedBook {
                    BookDetailSheet(
                        book: book,
                        onRemove: {
                            showBookDetail = false
                            Task {
                                await viewModel.removeBook(book)
                            }
                        },
                        onDismiss: {
                            showBookDetail = false
                        }
                    )
                    .presentationDetents([.medium, .large])
                }
            }
            .fullScreenCover(isPresented: $showAuditMode) {
                AuditModeView()
                    .onDisappear {
                        // Refresh bookshelf when audit mode closes
                        Task {
                            await viewModel.fetchBookshelf()
                        }
                    }
            }
            .sheet(isPresented: $showManualEntry) {
                ManualBookEntrySheet { title, author in
                    Task {
                        await viewModel.addBookManually(title: title, author: author)
                        showManualEntry = false
                    }
                }
            }
            .alert("Clear Bookshelf", isPresented: $showClearConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All", role: .destructive) {
                    Task {
                        await viewModel.clearBookshelf()
                    }
                }
            } message: {
                Text("Are you sure you want to remove all books from your bookshelf? This cannot be undone.")
            }
            .toast(isPresented: $viewModel.showSuccess, message: viewModel.successMessage)
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        ZStack {
            // Base warm color
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.92, blue: 0.88),
                    Color(red: 0.9, green: 0.85, blue: 0.78)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Subtle texture overlay
            GeometryReader { geometry in
                Canvas { context, size in
                    // Create subtle noise texture
                    for _ in 0..<200 {
                        let x = CGFloat.random(in: 0...size.width)
                        let y = CGFloat.random(in: 0...size.height)
                        let opacity = Double.random(in: 0.02...0.05)
                        
                        context.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2)),
                            with: .color(Color.brown.opacity(opacity))
                        )
                    }
                }
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .brown))
                .scaleEffect(1.5)
            
            Text("Loading your bookshelf...")
                .font(.system(size: 16, design: .serif))
                .foregroundColor(.secondary)
        }
    }
    
    private var bookshelfContent: some View {
        VStack(spacing: 0) {
            // Stats header
            statsHeader
                .padding(.horizontal)
                .padding(.top, 8)
            
            // Help text
            Text(viewModel.isEditMode 
                 ? "Drag books to reorder • Tap Done when finished" 
                 : "Tap book to see cover • Long press to remove")
                .font(.system(size: 12))
                .foregroundColor(viewModel.isEditMode ? .orange : .secondary)
                .padding(.top, 8)
                .animation(.easeInOut, value: viewModel.isEditMode)
            
            // Edit mode indicator
            if viewModel.isEditMode {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.arrow.down.circle.fill")
                        .foregroundColor(.orange)
                    Text("Rearrange Mode")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.orange.opacity(0.15))
                )
                .padding(.top, 8)
                .transition(.scale.combined(with: .opacity))
            }
            
            // 3D Bookshelf
            Bookshelf3DView(
                books: viewModel.books,
                isEditMode: viewModel.isEditMode,
                onBookTap: { book in
                    // Tap is now handled by Book3DView for rotation
                },
                onBookLongPress: { book in
                    selectedBook = book
                    showBookDetail = true
                },
                onMove: { fromIndex, toIndex in
                    viewModel.moveBookDirectly(fromIndex: fromIndex, toIndex: toIndex)
                }
            )
        }
        .animation(.spring(response: 0.3), value: viewModel.isEditMode)
    }
    
    private var statsHeader: some View {
        HStack(spacing: 16) {
            // Book count with icon
            HStack(spacing: 8) {
                Image(systemName: "books.vertical.fill")
                    .foregroundColor(.brown)
                
                Text("\(viewModel.totalBooks) book\(viewModel.totalBooks == 1 ? "" : "s")")
                    .font(.system(size: 15, weight: .medium, design: .serif))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.brown.opacity(0.1))
            )
            
            Spacer()
            
            // Connection status
            HStack(spacing: 6) {
                Circle()
                    .fill(viewModel.isServerReachable ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                
                Text(viewModel.isServerReachable ? "Connected" : "Offline")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            // Last updated
            if let lastUpdated = viewModel.formattedLastUpdated {
                Text("• \(lastUpdated)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Toast View Modifier
struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        
                        Text(message)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
                    )
                    .padding(.bottom, 30)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }
                }
            }
        }
        .animation(.spring(response: 0.4), value: isPresented)
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, message: String) -> some View {
        modifier(ToastModifier(isPresented: isPresented, message: message))
    }
}

#Preview {
    BookshelfView(viewModel: BookshelfViewModel())
}
