//
//  ContentView.swift
//  digital-twins
//
//  Main container view
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = BookshelfViewModel()
    
    var body: some View {
        BookshelfView(viewModel: viewModel)
    }
}

#Preview {
    ContentView()
}

