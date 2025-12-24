//
//  BookCardView.swift
//  digital-twins
//
//  Individual book card for grid display
//

import SwiftUI

struct BookCardView: View {
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Book cover
            BookCoverView(book: book)
                .aspectRatio(2/3, contentMode: .fit)
            
            // Book info
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(book.author)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    BookCardView(book: Book(title: "The Great Gatsby", author: "F. Scott Fitzgerald", coverUrl: nil))
        .frame(width: 150)
        .padding()
}

