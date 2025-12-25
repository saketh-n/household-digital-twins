//
//  Book3DView.swift
//  digital-twins
//
//  3D book on shelf - tap to flip and show cover
//

import SwiftUI

struct Book3DView: View {
    let book: Book
    let height: CGFloat
    let onLongPress: () -> Void
    
    @State private var isFlipped = false
    @State private var isPressed = false
    
    // Book dimensions
    private var bookWidth: CGFloat {
        let baseWidth: CGFloat = 26
        let extraWidth = CGFloat(min(book.title.count, 25)) * 0.5
        return baseWidth + extraWidth
    }
    
    private let coverWidth: CGFloat = 110
    
    // Generate consistent color based on book title
    private var bookColor: Color {
        let hash = abs(book.title.hashValue)
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.5, brightness: 0.6)
    }
    
    private var bookColorDark: Color {
        let hash = abs(book.title.hashValue)
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.35)
    }
    
    var body: some View {
        ZStack {
            // Dimmed backdrop when flipped
            if isFlipped {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isFlipped = false
                        }
                    }
                    .zIndex(1)
            }
            
            // The book
            ZStack {
                // Back side (cover) - shown when flipped
                bookCover
                    .opacity(isFlipped ? 1 : 0)
                    .scaleEffect(x: isFlipped ? 1 : 0.8, y: isFlipped ? 1 : 0.9)
                
                // Front side (spine) - shown normally
                bookSpine
                    .opacity(isFlipped ? 0 : 1)
                    .scaleEffect(x: isFlipped ? 0.5 : 1, y: isFlipped ? 0.8 : 1)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .scaleEffect(isFlipped ? 1.5 : 1.0)
            .offset(y: isFlipped ? -30 : 0)
            .zIndex(isFlipped ? 10 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isFlipped)
            .animation(.spring(response: 0.2), value: isPressed)
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    isFlipped.toggle()
                }
            }
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in
                        isPressed = false
                        onLongPress()
                    }
            )
        }
        .frame(width: isFlipped ? coverWidth + 20 : bookWidth)
    }
    
    // MARK: - Spine View (on shelf)
    
    private var bookSpine: some View {
        ZStack {
            // Main spine
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [
                            bookColor.opacity(0.95),
                            bookColorDark,
                            bookColor.opacity(0.85)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: bookWidth, height: height)
                .shadow(color: .black.opacity(0.4), radius: 2, x: 2, y: 0)
            
            // Spine decorations
            VStack(spacing: 0) {
                // Top band
                Rectangle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: bookWidth - 6, height: 3)
                    .padding(.top, 12)
                
                Spacer()
                
                // Title (rotated)
                Text(book.title)
                    .font(.system(size: 9, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.6), radius: 1, x: 0, y: 1)
                    .rotationEffect(.degrees(-90))
                    .fixedSize()
                    .frame(width: height - 60)
                    .lineLimit(1)
                
                Spacer()
                
                // Author
                Text(book.author.components(separatedBy: " ").last ?? book.author)
                    .font(.system(size: 7, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))
                    .rotationEffect(.degrees(-90))
                    .fixedSize()
                    .frame(width: 40)
                    .lineLimit(1)
                    .padding(.bottom, 8)
                
                // Bottom band
                Rectangle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: bookWidth - 6, height: 3)
                    .padding(.bottom, 12)
            }
            .frame(width: bookWidth, height: height)
            
            // Spine crease
            HStack {
                Rectangle()
                    .fill(Color.black.opacity(0.25))
                    .frame(width: 1)
                Spacer()
            }
            .frame(width: bookWidth, height: height)
            
            // Page edges (right side)
            HStack {
                Spacer()
                ZStack {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.9), Color.gray.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 5)
                    
                    // Page lines
                    VStack(spacing: 3) {
                        ForEach(0..<Int(height / 10), id: \.self) { _ in
                            Rectangle()
                                .fill(Color.gray.opacity(0.25))
                                .frame(width: 4, height: 0.5)
                        }
                    }
                }
                .frame(width: 5, height: height - 8)
            }
            .frame(width: bookWidth, height: height)
            
            // Top edge (pages)
            VStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.85), Color.gray.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: bookWidth - 2, height: 4)
                Spacer()
            }
            .frame(width: bookWidth, height: height)
        }
        .frame(width: bookWidth, height: height)
    }
    
    // MARK: - Cover View (when flipped)
    
    private var bookCover: some View {
        ZStack {
            // Cover background
            RoundedRectangle(cornerRadius: 4)
                .fill(bookColor)
                .shadow(color: .black.opacity(0.4), radius: 8, x: 4, y: 4)
            
            // Cover image or fallback
            if let coverUrl = book.coverUrl, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: coverWidth - 6, height: height - 6)
                            .clipped()
                            .cornerRadius(3)
                    case .failure:
                        coverFallback
                    case .empty:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    @unknown default:
                        coverFallback
                    }
                }
            } else {
                coverFallback
            }
            
            // Cover border/edge effect
            RoundedRectangle(cornerRadius: 4)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.3), Color.black.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
            
            // Spine edge on left
            HStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [bookColorDark, bookColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 8)
                    .cornerRadius(4, corners: [.topLeft, .bottomLeft])
                Spacer()
            }
        }
        .frame(width: coverWidth, height: height)
    }
    
    private var coverFallback: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [bookColor, bookColorDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 12) {
                Spacer()
                
                // Book icon
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.3))
                
                // Title
                Text(book.title)
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 12)
                
                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 40, height: 1)
                
                // Author
                Text(book.author)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
                    .padding(.horizontal, 12)
                
                Spacer()
            }
        }
        .frame(width: coverWidth - 6, height: height - 6)
        .cornerRadius(3)
    }
}

// Helper for rounded corners on specific sides
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ZStack {
        Color.brown.opacity(0.3).ignoresSafeArea()
        
        HStack(alignment: .bottom, spacing: 4) {
            Book3DView(
                book: Book(title: "The Great Gatsby", author: "F. Scott Fitzgerald", coverUrl: "https://covers.openlibrary.org/b/id/8432047-M.jpg"),
                height: 150,
                onLongPress: {}
            )
            Book3DView(
                book: Book(title: "1984", author: "George Orwell", coverUrl: nil),
                height: 155,
                onLongPress: {}
            )
            Book3DView(
                book: Book(title: "Dune", author: "Frank Herbert", coverUrl: nil),
                height: 148,
                onLongPress: {}
            )
        }
        .padding(.bottom, 50)
    }
}
