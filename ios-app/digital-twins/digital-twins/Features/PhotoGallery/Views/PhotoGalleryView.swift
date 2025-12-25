//
//  PhotoGalleryView.swift
//  digital-twins
//
//  View for capturing and managing multiple photos before processing
//

import SwiftUI

struct PhotoGalleryView: View {
    @StateObject private var viewModel = PhotoGalleryViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let mode: GalleryMode
    let onComplete: ([Book]) -> Void
    
    enum GalleryMode {
        case regularScan  // Adds directly to bookshelf
        case audit        // Adds to audit session
    }
    
    @State private var selectedPhoto: CapturedPhoto?
    @State private var showPhotoDetail = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                backgroundGradient
                
                VStack(spacing: 0) {
                    if viewModel.photos.isEmpty {
                        emptyState
                    } else {
                        galleryContent
                    }
                    
                    // Bottom action bar
                    bottomActionBar
                }
            }
            .navigationTitle(mode == .audit ? "Audit Photos" : "Scan Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(mode == .audit ? .white : .primary)
                }
                
                if !viewModel.photos.isEmpty && !viewModel.isProcessing {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear All") {
                            viewModel.clearPhotos()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showCamera) {
                PhotoCaptureView { image in
                    viewModel.addPhoto(image)
                }
            }
            .sheet(isPresented: $showPhotoDetail) {
                if let photo = selectedPhoto {
                    PhotoDetailView(photo: photo) {
                        viewModel.removePhoto(photo)
                        showPhotoDetail = false
                    }
                }
            }
            .overlay {
                if viewModel.isProcessing {
                    processingOverlay
                }
            }
            .overlay(alignment: .top) {
                if let toast = viewModel.toastMessage {
                    toastView(toast)
                }
            }
            .onChange(of: viewModel.processingComplete) { _, complete in
                if complete {
                    onComplete(viewModel.detectedBooks)
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        Group {
            if mode == .audit {
                LinearGradient(
                    colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            } else {
                LinearGradient(
                    colors: [Color(.systemBackground), Color.teal.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "photo.stack")
                .font(.system(size: 80))
                .foregroundColor(mode == .audit ? Color(hex: "00d4aa").opacity(0.5) : .teal.opacity(0.5))
            
            VStack(spacing: 12) {
                Text("No Photos Yet")
                    .font(.title2.weight(.bold))
                    .foregroundColor(mode == .audit ? .white : .primary)
                
                Text("Take photos of your bookshelf.\nYou can capture multiple sections\nand process them all at once.")
                    .font(.subheadline)
                    .foregroundColor(mode == .audit ? .gray : .secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                viewModel.showCamera = true
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Take First Photo")
                }
                .font(.headline)
                .foregroundColor(mode == .audit ? Color(hex: "1a1a2e") : .white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(mode == .audit ? Color(hex: "00d4aa") : Color.teal)
                .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Gallery Content
    private var galleryContent: some View {
        VStack(spacing: 0) {
            // Stats header
            HStack {
                Label("\(viewModel.photos.count) photo\(viewModel.photos.count == 1 ? "" : "s")", systemImage: "photo.stack")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(mode == .audit ? .white : .primary)
                
                Spacer()
                
                if viewModel.photos.contains(where: { $0.isProcessed }) {
                    let processedCount = viewModel.photos.filter { $0.isProcessed }.count
                    Text("\(processedCount) processed")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(mode == .audit ? Color.white.opacity(0.05) : Color(.secondarySystemBackground))
            
            // Photo grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(viewModel.photos) { photo in
                        PhotoThumbnailView(
                            photo: photo,
                            mode: mode
                        ) {
                            selectedPhoto = photo
                            showPhotoDetail = true
                        } onDelete: {
                            viewModel.removePhoto(photo)
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Bottom Action Bar
    private var bottomActionBar: some View {
        HStack(spacing: 16) {
            // Add more photos
            Button {
                viewModel.showCamera = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                    Text("Add Photo")
                        .font(.caption2)
                }
                .foregroundColor(mode == .audit ? .white : .teal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(mode == .audit ? Color.white.opacity(0.1) : Color.teal.opacity(0.1))
                .cornerRadius(12)
            }
            .disabled(viewModel.isProcessing)
            
            // Process all photos
            Button {
                Task {
                    if mode == .audit {
                        await viewModel.processAllPhotosForAudit()
                    } else {
                        await viewModel.processAllPhotos()
                    }
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "wand.and.stars")
                        .font(.title2)
                    Text("Process All")
                        .font(.caption2)
                }
                .foregroundColor(mode == .audit ? Color(hex: "1a1a2e") : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    viewModel.photos.isEmpty 
                        ? Color.gray.opacity(0.5) 
                        : (mode == .audit ? Color(hex: "00d4aa") : Color.teal)
                )
                .cornerRadius(12)
            }
            .disabled(viewModel.photos.isEmpty || viewModel.isProcessing)
        }
        .padding()
        .background(
            mode == .audit 
                ? Color(hex: "1a1a2e").opacity(0.95)
                : Color(.systemBackground).opacity(0.95)
        )
    }
    
    // MARK: - Processing Overlay
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Animated icon
                Image(systemName: "text.viewfinder")
                    .font(.system(size: 50))
                    .foregroundColor(mode == .audit ? Color(hex: "00d4aa") : .teal)
                    .symbolEffect(.pulse)
                
                VStack(spacing: 8) {
                    Text("Processing Photos")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Analyzing photo \(viewModel.currentPhotoIndex) of \(viewModel.photos.count)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Progress bar
                VStack(spacing: 8) {
                    ProgressView(value: viewModel.processingProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: mode == .audit ? Color(hex: "00d4aa") : .teal))
                        .frame(width: 200)
                    
                    Text("\(Int(viewModel.processingProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(40)
            .background(Color(hex: "1a1a2e"))
            .cornerRadius(20)
        }
    }
    
    // MARK: - Toast
    private func toastView(_ message: String) -> some View {
        Text(message)
            .font(.subheadline.weight(.medium))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(mode == .audit ? Color(hex: "00d4aa") : Color.teal)
            .cornerRadius(25)
            .shadow(radius: 10)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation {
                        viewModel.dismissToast()
                    }
                }
            }
    }
}

// MARK: - Photo Thumbnail View
struct PhotoThumbnailView: View {
    let photo: CapturedPhoto
    let mode: PhotoGalleryView.GalleryMode
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: photo.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(strokeColor, lineWidth: photo.isProcessed ? 2 : 0)
                    )
                
                // Status badge
                if photo.isProcessed {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                        if photo.booksFound > 0 {
                            Text("\(photo.booksFound)")
                                .font(.caption2.weight(.bold))
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.green)
                    .cornerRadius(10)
                    .padding(4)
                } else if photo.processingFailed {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.red)
                        .cornerRadius(10)
                        .padding(4)
                }
                
                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                }
                .padding(6)
                .offset(x: 4, y: -4)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var strokeColor: Color {
        if photo.processingFailed {
            return .red
        } else if photo.isProcessed {
            return .green
        }
        return .clear
    }
}

// MARK: - Photo Detail View
struct PhotoDetailView: View {
    let photo: CapturedPhoto
    let onDelete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(uiImage: photo.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            .navigationTitle("Photo Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.8), for: .navigationBar)
        }
    }
}

// MARK: - Photo Capture View (simplified camera)
struct PhotoCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    let onCapture: (UIImage) -> Void
    
    @State private var showPicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "1a1a2e").ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 80))
                        .foregroundColor(Color(hex: "00d4aa"))
                    
                    Text("Add Photo")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Button {
                            sourceType = .camera
                            showPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Take Photo")
                            }
                            .font(.headline)
                            .foregroundColor(Color(hex: "1a1a2e"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "00d4aa"))
                            .cornerRadius(12)
                        }
                        
                        Button {
                            sourceType = .photoLibrary
                            showPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text("Choose from Library")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showPicker) {
                ImagePicker(sourceType: sourceType) { image in
                    onCapture(image)
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    PhotoGalleryView(mode: .regularScan) { _ in }
}

