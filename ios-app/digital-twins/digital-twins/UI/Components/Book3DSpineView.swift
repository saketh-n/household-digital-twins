//
//  Book3DSpineView.swift
//  digital-twins
//
//  3D book spine for realistic bookshelf display
//

import SwiftUI

struct Book3DSpineView: View {
    let book: Book
    let height: CGFloat
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    @State private var isPressed = false
    @State private var showCover = false
    
    // Generate consistent colors based on book title
    private var spineColor: Color {
        let hash = abs(book.title.hashValue)
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.7)
    }
    
    private var darkSpineColor: Color {
        let hash = abs(book.title.hashValue)
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.7, brightness: 0.4)
    }
    
    // Book width based on title length (simulate thickness)
    private var bookWidth: CGFloat {
        let baseWidth: CGFloat = 28
        let extraWidth = CGFloat(min(book.title.count, 30)) * 0.8
        return baseWidth + extraWidth
    }
    
    var body: some View {
        ZStack {
            // Main spine face
            bookSpine
            
            // Top edge (3D effect)
            bookTopEdge
            
            // Right edge (3D depth)
            bookRightEdge
        }
        .frame(width: bookWidth, height: height)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3), value: isPressed)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
            isPressed = pressing
        }) {
            onLongPress()
        }
    }
    
    private var bookSpine: some View {
        ZStack {
            // Spine background with gradient
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [
                            spineColor.opacity(0.9),
                            darkSpineColor,
                            spineColor.opacity(0.8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            // Decorative lines
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 2)
                    .padding(.horizontal, 4)
                    .padding(.top, 8)
                
                Spacer()
                
                // Title text (rotated)
                Text(book.title)
                    .font(.system(size: 9, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                    .rotationEffect(.degrees(-90))
                    .fixedSize()
                    .frame(width: height - 40)
                    .lineLimit(1)
                
                Spacer()
                
                // Author (smaller)
                Text(book.author.components(separatedBy: " ").last ?? book.author)
                    .font(.system(size: 7, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .rotationEffect(.degrees(-90))
                    .fixedSize()
                    .frame(width: 50)
                    .lineLimit(1)
                    .padding(.bottom, 8)
                
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 2)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 8)
            }
            
            // Subtle spine crease
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 1)
                Spacer()
            }
        }
        .shadow(color: .black.opacity(0.3), radius: 2, x: 2, y: 0)
    }
    
    private var bookTopEdge: some View {
        VStack {
            // Top page edges
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.9), Color.gray.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 4)
                .offset(y: -2)
            
            Spacer()
        }
    }
    
    private var bookRightEdge: some View {
        HStack {
            Spacer()
            
            // Page edges on the right
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            Color.gray.opacity(0.4),
                            Color.white.opacity(0.9)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 5)
                .overlay(
                    // Page lines
                    VStack(spacing: 2) {
                        ForEach(0..<Int(height / 8), id: \.self) { _ in
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 0.5)
                        }
                    }
                    .padding(.vertical, 4)
                )
        }
    }
}

#Preview {
    HStack(spacing: 2) {
        Book3DSpineView(
            book: Book(title: "The Great Gatsby", author: "F. Scott Fitzgerald", coverUrl: nil),
            height: 180,
            onTap: {},
            onLongPress: {}
        )
        Book3DSpineView(
            book: Book(title: "1984", author: "George Orwell", coverUrl: nil),
            height: 180,
            onTap: {},
            onLongPress: {}
        )
        Book3DSpineView(
            book: Book(title: "To Kill a Mockingbird", author: "Harper Lee", coverUrl: nil),
            height: 180,
            onTap: {},
            onLongPress: {}
        )
    }
    .padding()
    .background(Color.brown.opacity(0.3))
}

