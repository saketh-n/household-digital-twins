//
//  BookDetailSheet.swift
//  digital-twins
//
//  Book detail modal with remove option
//

import SwiftUI

struct BookDetailSheet: View {
    let book: Book
    let onRemove: () -> Void
    let onDismiss: () -> Void
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Book cover
                    bookCover
                        .padding(.top, 20)
                    
                    // Book info
                    VStack(spacing: 12) {
                        Text(book.title)
                            .font(.system(size: 24, weight: .bold, design: .serif))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        Text("by \(book.author)")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                    
                    // Remove button
                    Button(action: { showDeleteConfirmation = true }) {
                        HStack(spacing: 10) {
                            Image(systemName: "trash.fill")
                            Text("Remove from Bookshelf")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.red)
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color.brown.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Book Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Remove Book?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive) {
                    onRemove()
                }
            } message: {
                Text("Are you sure you want to remove '\(book.title)' from your bookshelf?")
            }
        }
    }
    
    private var bookCover: some View {
        Group {
            if let coverUrl = book.coverUrl, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        fallbackCover
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 280)
                            .cornerRadius(8)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 5, y: 10)
                    case .failure:
                        fallbackCover
                    @unknown default:
                        fallbackCover
                    }
                }
            } else {
                fallbackCover
            }
        }
    }
    
    private var fallbackCover: some View {
        let hash = abs(book.title.hashValue)
        let hue = Double(hash % 360) / 360.0
        
        return ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hue: hue, saturation: 0.5, brightness: 0.8),
                            Color(hue: hue, saturation: 0.6, brightness: 0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 16) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.white.opacity(0.9))
                
                Text(book.title)
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
        .frame(width: 180, height: 280)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 5, y: 10)
    }
}

#Preview {
    BookDetailSheet(
        book: Book(title: "The Great Gatsby", author: "F. Scott Fitzgerald", coverUrl: nil),
        onRemove: {},
        onDismiss: {}
    )
}

