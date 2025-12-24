//
//  BookCoverView.swift
//  digital-twins
//
//  Book cover image component with loading state
//

import SwiftUI

struct BookCoverView: View {
    let book: Book
    
    @State private var isLoading = true
    @State private var loadFailed = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hue: bookHue, saturation: 0.3, brightness: 0.9),
                                Color(hue: bookHue, saturation: 0.4, brightness: 0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 2, y: 4)
                
                if let coverUrl = book.coverUrl, let url = URL(string: coverUrl), !loadFailed {
                    // Async cover image
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                                .cornerRadius(8)
                        case .failure:
                            fallbackCover
                                .onAppear { loadFailed = true }
                        @unknown default:
                            fallbackCover
                        }
                    }
                } else {
                    // Fallback cover
                    fallbackCover
                }
            }
        }
    }
    
    private var fallbackCover: some View {
        VStack(spacing: 8) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 28))
                .foregroundColor(.white.opacity(0.9))
            
            Text(book.title)
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(.horizontal, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Generate consistent hue based on book title
    private var bookHue: Double {
        let hash = book.title.hash
        return Double(abs(hash) % 360) / 360.0
    }
}

#Preview {
    HStack(spacing: 16) {
        BookCoverView(book: Book(title: "The Great Gatsby", author: "F. Scott Fitzgerald", coverUrl: nil))
            .frame(width: 100, height: 150)
        
        BookCoverView(book: Book(title: "1984", author: "George Orwell", coverUrl: "https://covers.openlibrary.org/b/id/7222246-M.jpg"))
            .frame(width: 100, height: 150)
    }
    .padding()
}

