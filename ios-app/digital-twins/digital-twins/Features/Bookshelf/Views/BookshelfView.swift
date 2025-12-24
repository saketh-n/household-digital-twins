//
//  BookshelfView.swift
//  digital-twins
//
//  Main bookshelf display view
//

import SwiftUI

struct BookshelfView: View {
    @ObservedObject var viewModel: BookshelfViewModel
    
    @State private var showClearConfirmation = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.teal.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Main content
                if viewModel.isLoading && viewModel.books.isEmpty {
                    loadingView
                } else if viewModel.books.isEmpty && !viewModel.showError {
                    EmptyStateView(onScan: viewModel.openCamera)
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
                    if viewModel.hasBooks {
                        Menu {
                            Button(role: .destructive, action: { showClearConfirmation = true }) {
                                Label("Clear Bookshelf", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.openCamera) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.teal, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
            }
            .sheet(isPresented: $viewModel.showCamera) {
                CameraView { image in
                    Task {
                        await viewModel.scanImage(image)
                    }
                }
            }
            .alert("Clear Bookshelf", isPresented: $showClearConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
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
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .teal))
                .scaleEffect(1.5)
            
            Text("Loading your bookshelf...")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
    }
    
    private var bookshelfContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Stats header
                statsHeader
                    .padding(.horizontal)
                
                // Book grid
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(viewModel.books) { book in
                        BookCardView(book: book)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
            .padding(.top)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    private var statsHeader: some View {
        HStack(spacing: 16) {
            // Book count
            HStack(spacing: 8) {
                Image(systemName: "book.closed.fill")
                    .foregroundColor(.teal)
                
                Text("\(viewModel.totalBooks) book\(viewModel.totalBooks == 1 ? "" : "s")")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.teal.opacity(0.1))
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
                Text("Updated \(lastUpdated)")
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

