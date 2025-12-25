//
//  ManualBookEntrySheet.swift
//  digital-twins
//
//  Sheet for manually adding a book by title and author
//

import SwiftUI

struct ManualBookEntrySheet: View {
    let onAdd: (String, String) -> Void  // (title, author)
    
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var author = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title, author
    }
    
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !author.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Header illustration
                    VStack(spacing: 16) {
                        Image(systemName: "text.book.closed.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "00d4aa"), Color(hex: "00b894")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        Text("Add Book Manually")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.white)
                        
                        Text("Enter the book details below")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 24)
                    
                    // Input fields
                    VStack(spacing: 20) {
                        // Title field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Book Title")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.gray)
                            
                            TextField("", text: $title, prompt: Text("Enter book title").foregroundColor(.gray.opacity(0.7)))
                                .textFieldStyle(DarkTextFieldStyle())
                                .focused($focusedField, equals: .title)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .author
                                }
                        }
                        
                        // Author field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Author")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.gray)
                            
                            TextField("", text: $author, prompt: Text("Enter author name").foregroundColor(.gray.opacity(0.7)))
                                .textFieldStyle(DarkTextFieldStyle())
                                .focused($focusedField, equals: .author)
                                .submitLabel(.done)
                                .onSubmit {
                                    if isValid {
                                        addBook()
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Add button
                    Button {
                        addBook()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Book")
                        }
                        .font(.headline)
                        .foregroundColor(isValid ? Color(hex: "1a1a2e") : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isValid ? Color(hex: "00d4aa") : Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .disabled(!isValid)
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .onAppear {
                focusedField = .title
            }
        }
    }
    
    private func addBook() {
        onAdd(title, author)
    }
}

// MARK: - Dark Text Field Style
struct DarkTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(16)
            .background(Color.white.opacity(0.08))
            .foregroundColor(.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

#Preview {
    ManualBookEntrySheet { title, author in
        print("Added: \(title) by \(author)")
    }
}

