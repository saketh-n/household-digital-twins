//
//  Bookshelf3DView.swift
//  digital-twins
//
//  3D wooden bookshelf with realistic books - tap books to see covers
//  Supports drag-and-drop reordering in edit mode
//

import SwiftUI

struct Bookshelf3DView: View {
    let books: [Book]
    var isEditMode: Bool = false
    let onBookTap: (Book) -> Void
    let onBookLongPress: (Book) -> Void
    var onMove: ((Int, Int) -> Void)?
    
    @State private var shelfWidth: CGFloat = 350
    @State private var draggingBook: Book?
    @State private var draggingOffset: CGSize = .zero
    @State private var draggedOverIndex: Int?
    
    private let bookHeight: CGFloat = 150
    private let shelfHeight: CGFloat = 175
    
    // Flatten books for drag and drop (single row for simplicity in edit mode)
    private var allBooksFlat: [Book] { books }
    
    // Group books into shelves based on available width
    private var bookShelves: [[Book]] {
        var shelves: [[Book]] = []
        var currentShelf: [Book] = []
        var currentWidth: CGFloat = 0
        let maxWidth = shelfWidth - 50
        
        for book in books {
            let bookWidth = calculateBookWidth(for: book)
            
            if currentWidth + bookWidth > maxWidth && !currentShelf.isEmpty {
                shelves.append(currentShelf)
                currentShelf = [book]
                currentWidth = bookWidth + 3
            } else {
                currentShelf.append(book)
                currentWidth += bookWidth + 3
            }
        }
        
        if !currentShelf.isEmpty {
            shelves.append(currentShelf)
        }
        
        while shelves.count < 2 {
            shelves.append([])
        }
        
        return shelves
    }
    
    private func calculateBookWidth(for book: Book) -> CGFloat {
        let baseWidth: CGFloat = 26
        let extraWidth = CGFloat(min(book.title.count, 25)) * 0.5
        return baseWidth + extraWidth
    }
    
    private func globalIndex(for book: Book) -> Int? {
        books.firstIndex(where: { $0.id == book.id })
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = min(geometry.size.width - 24, 400)
            
            ScrollView(.vertical, showsIndicators: false) {
                ZStack {
                    VStack(spacing: 0) {
                        topCrown(width: width)
                        
                        ForEach(Array(bookShelves.enumerated()), id: \.offset) { index, shelfBooks in
                            shelfUnit(books: shelfBooks, width: width, index: index)
                        }
                        
                        baseBoard(width: width)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 20)
            }
            .onAppear {
                shelfWidth = width
            }
        }
    }
    
    // MARK: - Shelf Components
    
    private func topCrown(width: CGFloat) -> some View {
        ZStack {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.6, green: 0.4, blue: 0.25),
                                Color(red: 0.5, green: 0.32, blue: 0.18)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 8)
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.5, green: 0.32, blue: 0.18),
                                Color(red: 0.4, green: 0.25, blue: 0.12)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 14)
            }
            .frame(width: width + 8)
            
            VStack {
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 2)
                Spacer()
            }
            .frame(width: width + 8, height: 22)
        }
        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
    }
    
    private func shelfUnit(books: [Book], width: CGFloat, index: Int) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                sidePanel(height: shelfHeight, isLeft: true)
                
                ZStack(alignment: .bottom) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.22, green: 0.15, blue: 0.1),
                                    Color(red: 0.18, green: 0.12, blue: 0.08)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            GeometryReader { geo in
                                ForEach(0..<8, id: \.self) { i in
                                    Rectangle()
                                        .fill(Color.black.opacity(0.05))
                                        .frame(width: geo.size.width, height: 1)
                                        .offset(y: CGFloat(i) * 22 + 10)
                                }
                            }
                        )
                    
                    // Books with drag support
                    HStack(alignment: .bottom, spacing: 3) {
                        ForEach(books) { book in
                            bookView(book: book)
                        }
                        
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 4)
                }
                .frame(width: width - 28, height: shelfHeight - 20)
                
                sidePanel(height: shelfHeight, isLeft: false)
            }
            
            shelfBoard(width: width)
        }
    }
    
    @ViewBuilder
    private func bookView(book: Book) -> some View {
        let isDragging = draggingBook?.id == book.id
        let bookIndex = globalIndex(for: book) ?? 0
        let isDropTarget = draggedOverIndex == bookIndex && !isDragging
        
        ZStack {
            // Drop indicator
            if isDropTarget && isEditMode {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.orange.opacity(0.3))
                    .frame(width: calculateBookWidth(for: book) + 8, height: bookHeight + 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.orange, style: StrokeStyle(lineWidth: 2, dash: [5]))
                    )
            }
            
            Book3DView(
                book: book,
                height: bookHeight + CGFloat.random(in: -8...8),
                onLongPress: { 
                    if !isEditMode {
                        onBookLongPress(book) 
                    }
                }
            )
            .opacity(isDragging ? 0.3 : 1.0)
            .overlay(
                // Edit mode indicator
                Group {
                    if isEditMode && !isDragging {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Circle().fill(Color.orange))
                                    .offset(x: 4, y: -4)
                            }
                            Spacer()
                        }
                    }
                }
            )
            .scaleEffect(isDragging ? 1.1 : 1.0)
            .gesture(
                isEditMode ? 
                DragGesture()
                    .onChanged { value in
                        if draggingBook == nil {
                            draggingBook = book
                        }
                        draggingOffset = value.translation
                        
                        // Calculate which book we're over
                        let horizontalMovement = value.translation.width
                        let bookWidth = calculateBookWidth(for: book) + 3
                        let indexOffset = Int(horizontalMovement / bookWidth)
                        let newIndex = max(0, min(books.count - 1, bookIndex + indexOffset))
                        
                        if newIndex != draggedOverIndex {
                            draggedOverIndex = newIndex
                            // Haptic feedback
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }
                    }
                    .onEnded { _ in
                        if let fromIndex = globalIndex(for: book),
                           let toIndex = draggedOverIndex,
                           fromIndex != toIndex {
                            onMove?(fromIndex, toIndex)
                        }
                        
                        withAnimation(.spring(response: 0.3)) {
                            draggingBook = nil
                            draggingOffset = .zero
                            draggedOverIndex = nil
                        }
                    }
                : nil
            )
            .animation(.spring(response: 0.3), value: isDragging)
        }
        .offset(isDragging ? draggingOffset : .zero)
        .zIndex(isDragging ? 100 : 0)
    }
    
    private func sidePanel(height: CGFloat, isLeft: Bool) -> some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.52, green: 0.33, blue: 0.2),
                            Color(red: 0.42, green: 0.26, blue: 0.14),
                            Color(red: 0.48, green: 0.3, blue: 0.17)
                        ],
                        startPoint: isLeft ? .trailing : .leading,
                        endPoint: isLeft ? .leading : .trailing
                    )
                )
            
            VStack(spacing: 12) {
                ForEach(0..<Int(height / 15), id: \.self) { _ in
                    Rectangle()
                        .fill(Color.black.opacity(Double.random(in: 0.02...0.06)))
                        .frame(height: CGFloat.random(in: 1...2))
                }
            }
            .padding(.vertical, 5)
        }
        .frame(width: 14, height: height)
        .shadow(color: .black.opacity(0.25), radius: 2, x: isLeft ? -1 : 1, y: 0)
    }
    
    private func shelfBoard(width: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.55, green: 0.36, blue: 0.22),
                            Color(red: 0.45, green: 0.28, blue: 0.15),
                            Color(red: 0.5, green: 0.32, blue: 0.18)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 14)
            
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 2)
                Spacer()
            }
            .frame(height: 14)
            
            VStack {
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.42, green: 0.26, blue: 0.14),
                                Color(red: 0.35, green: 0.2, blue: 0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 6)
            }
            .frame(height: 20)
            .offset(y: 3)
        }
        .frame(width: width, height: 20)
        .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 3)
    }
    
    private func baseBoard(width: CGFloat) -> some View {
        ZStack {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.48, green: 0.3, blue: 0.17),
                                Color(red: 0.38, green: 0.22, blue: 0.12)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 18)
                
                Rectangle()
                    .fill(Color(red: 0.3, green: 0.18, blue: 0.1))
                    .frame(height: 8)
            }
            .frame(width: width + 12)
        }
        .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 4)
    }
}

#Preview {
    ScrollView {
        Bookshelf3DView(
            books: [
                Book(title: "The Great Gatsby", author: "F. Scott Fitzgerald", coverUrl: "https://covers.openlibrary.org/b/id/8432047-M.jpg", order: 0),
                Book(title: "1984", author: "George Orwell", coverUrl: "https://covers.openlibrary.org/b/id/7222246-M.jpg", order: 1),
                Book(title: "To Kill a Mockingbird", author: "Harper Lee", coverUrl: nil, order: 2),
                Book(title: "Pride and Prejudice", author: "Jane Austen", coverUrl: nil, order: 3),
            ],
            isEditMode: true,
            onBookTap: { _ in },
            onBookLongPress: { _ in },
            onMove: { from, to in print("Move from \(from) to \(to)") }
        )
    }
    .background(Color(red: 0.95, green: 0.92, blue: 0.88))
}
