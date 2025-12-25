//
//  AuditDiffView.swift
//  digital-twins
//
//  View for displaying and applying audit differences
//

import SwiftUI

struct AuditDiffView: View {
    let diff: AuditDiff
    let summary: String
    let onApply: (Bool, Bool) -> Void  // (addNew, removeMissing)
    let onDiscard: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var addNewBooks = true
    @State private var removeMissingBooks = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Summary header
                        summaryCard
                        
                        // New books section
                        if !diff.booksToAdd.isEmpty {
                            diffSection(
                                title: "New Books Found",
                                subtitle: "\(diff.booksToAdd.count) book(s) to add",
                                books: diff.booksToAdd,
                                color: Color(hex: "00d4aa"),
                                icon: "plus.circle.fill"
                            )
                        }
                        
                        // Missing books section
                        if !diff.booksToRemove.isEmpty {
                            diffSection(
                                title: "Missing from Shelf",
                                subtitle: "\(diff.booksToRemove.count) book(s) not found",
                                books: diff.booksToRemove,
                                color: Color(hex: "ff6b6b"),
                                icon: "minus.circle.fill"
                            )
                        }
                        
                        // Matching books section
                        if !diff.booksMatching.isEmpty {
                            diffSection(
                                title: "Matching Books",
                                subtitle: "\(diff.booksMatching.count) book(s) confirmed",
                                books: diff.booksMatching,
                                color: Color(hex: "74b9ff"),
                                icon: "checkmark.circle.fill",
                                collapsed: true
                            )
                        }
                        
                        // No changes state
                        if diff.booksToAdd.isEmpty && diff.booksToRemove.isEmpty {
                            noChangesView
                        }
                        
                        // Action options
                        if !diff.booksToAdd.isEmpty || !diff.booksToRemove.isEmpty {
                            actionOptions
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
                
                // Bottom action bar
                VStack {
                    Spacer()
                    bottomActionBar
                }
            }
            .navigationTitle("Audit Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Summary Card
    private var summaryCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "00d4aa"))
            
            Text("Audit Complete")
                .font(.title2.weight(.bold))
                .foregroundColor(.white)
            
            Text(summary)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - Diff Section
    private func diffSection(
        title: String,
        subtitle: String,
        books: [Book],
        color: Color,
        icon: String,
        collapsed: Bool = false
    ) -> some View {
        DisclosureGroup {
            VStack(spacing: 8) {
                ForEach(books) { book in
                    bookRow(book, color: color)
                }
            }
            .padding(.top, 8)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
        }
        .tint(.white)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func bookRow(_ book: Book, color: Color) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: book.coverUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(color.opacity(0.2))
                    .overlay {
                        Image(systemName: "book.closed")
                            .foregroundColor(color.opacity(0.5))
                    }
            }
            .frame(width: 36, height: 50)
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
        }
        .padding(8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - No Changes View
    private var noChangesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 50))
                .foregroundColor(Color(hex: "00d4aa"))
            
            Text("Everything Matches!")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Your digital twin is in sync with your physical bookshelf.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - Action Options
    private var actionOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Apply Changes")
                .font(.headline)
                .foregroundColor(.white)
            
            if !diff.booksToAdd.isEmpty {
                Toggle(isOn: $addNewBooks) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Add new books")
                            .foregroundColor(.white)
                        Text("Add \(diff.booksToAdd.count) book(s) to your digital twin")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .tint(Color(hex: "00d4aa"))
            }
            
            if !diff.booksToRemove.isEmpty {
                Toggle(isOn: $removeMissingBooks) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Remove missing books")
                            .foregroundColor(.white)
                        Text("Remove \(diff.booksToRemove.count) book(s) not found on shelf")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .tint(Color(hex: "ff6b6b"))
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Bottom Action Bar
    private var bottomActionBar: some View {
        HStack(spacing: 16) {
            Button {
                onDiscard()
            } label: {
                Text("Discard")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
            }
            
            Button {
                onApply(addNewBooks, removeMissingBooks)
            } label: {
                Text("Apply Changes")
                    .font(.headline)
                    .foregroundColor(Color(hex: "1a1a2e"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "00d4aa"))
                    .cornerRadius(12)
            }
            .disabled(!addNewBooks && !removeMissingBooks && (!diff.booksToAdd.isEmpty || !diff.booksToRemove.isEmpty))
        }
        .padding()
        .background(
            Color(hex: "1a1a2e")
                .shadow(color: .black.opacity(0.3), radius: 10, y: -5)
        )
    }
}

#Preview {
    AuditDiffView(
        diff: AuditDiff(
            booksToAdd: [
                Book(title: "New Book 1", author: "Author A", coverUrl: nil),
                Book(title: "New Book 2", author: "Author B", coverUrl: nil)
            ],
            booksToRemove: [
                Book(title: "Missing Book", author: "Author C", coverUrl: nil)
            ],
            booksMatching: [
                Book(title: "Matching Book", author: "Author D", coverUrl: nil)
            ]
        ),
        summary: "2 new book(s) to add, 1 book(s) missing from shelf",
        onApply: { _, _ in },
        onDiscard: {}
    )
}

