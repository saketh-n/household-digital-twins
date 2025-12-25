//
//  WoodenShelfView.swift
//  digital-twins
//
//  Realistic wooden shelf component
//

import SwiftUI

struct WoodenShelfView: View {
    let width: CGFloat
    
    var body: some View {
        ZStack {
            // Main shelf surface
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.55, green: 0.35, blue: 0.2),
                            Color(red: 0.45, green: 0.28, blue: 0.15),
                            Color(red: 0.5, green: 0.32, blue: 0.18),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 16)
            
            // Wood grain effect
            HStack(spacing: 0) {
                ForEach(0..<Int(width / 60), id: \.self) { i in
                    Rectangle()
                        .fill(Color.black.opacity(Double.random(in: 0.03...0.08)))
                        .frame(width: CGFloat.random(in: 50...70))
                }
            }
            .frame(height: 16)
            
            // Top highlight
            VStack(spacing: 0) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 3)
                Spacer()
            }
            .frame(height: 16)
            
            // Bottom shadow
            VStack(spacing: 0) {
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.black.opacity(0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 4)
            }
            .frame(height: 16)
            
            // Front edge (3D lip)
            VStack {
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.25, blue: 0.12),
                                Color(red: 0.35, green: 0.2, blue: 0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 6)
                    .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 4)
            }
            .frame(height: 22)
            .offset(y: 3)
        }
        .frame(width: width, height: 22)
    }
}

// Side panel for bookshelf frame
struct ShelfSidePanel: View {
    let height: CGFloat
    let isLeft: Bool
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.5, green: 0.32, blue: 0.18),
                        Color(red: 0.4, green: 0.25, blue: 0.12),
                        Color(red: 0.45, green: 0.28, blue: 0.15),
                    ],
                    startPoint: isLeft ? .trailing : .leading,
                    endPoint: isLeft ? .leading : .trailing
                )
            )
            .frame(width: 14, height: height)
            .shadow(color: .black.opacity(0.3), radius: 3, x: isLeft ? -2 : 2, y: 0)
    }
}

#Preview {
    VStack {
        WoodenShelfView(width: 350)
        
        HStack {
            ShelfSidePanel(height: 200, isLeft: true)
            Spacer()
            ShelfSidePanel(height: 200, isLeft: false)
        }
        .frame(width: 350)
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}

