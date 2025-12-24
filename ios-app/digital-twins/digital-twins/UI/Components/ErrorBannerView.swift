//
//  ErrorBannerView.swift
//  digital-twins
//
//  Error display banner with retry action
//

import SwiftUI

struct ErrorBannerView: View {
    let error: APIError
    let onRetry: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                // Error icon
                Image(systemName: errorIcon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.red.opacity(0.8))
                    )
                
                // Error message
                VStack(alignment: .leading, spacing: 4) {
                    Text("Connection Error")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(error.errorDescription ?? "An unknown error occurred")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Dismiss button
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: onRetry) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Retry")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.accentColor)
                    )
                }
                
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var errorIcon: String {
        switch error {
        case .serverUnreachable, .timeout:
            return "wifi.slash"
        case .serverError:
            return "exclamationmark.triangle.fill"
        default:
            return "exclamationmark.circle.fill"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ErrorBannerView(
            error: .serverUnreachable,
            onRetry: {},
            onDismiss: {}
        )
        
        ErrorBannerView(
            error: .serverError(500, "Internal Server Error"),
            onRetry: {},
            onDismiss: {}
        )
    }
    .padding()
}

