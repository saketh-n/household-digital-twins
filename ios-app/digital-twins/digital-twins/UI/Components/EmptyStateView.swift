//
//  EmptyStateView.swift
//  digital-twins
//
//  Empty state when no books are in the bookshelf
//

import SwiftUI

struct EmptyStateView: View {
    let onScan: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated book icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.teal.opacity(0.2), Color.blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "books.vertical")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.teal, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isAnimating ? 1.05 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 2)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            
            VStack(spacing: 12) {
                Text("Your Bookshelf is Empty")
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundColor(.primary)
                
                Text("Scan a photo of your bookshelf to start building your digital library")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: onScan) {
                HStack(spacing: 10) {
                    Image(systemName: "camera.fill")
                    Text("Scan Bookshelf")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.teal, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: .teal.opacity(0.4), radius: 8, x: 0, y: 4)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    EmptyStateView(onScan: {})
}

