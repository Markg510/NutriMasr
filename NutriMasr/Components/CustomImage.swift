//
//  CustomImage.swift
//  NutriMasr
//
//  Created by Mark George on 28/06/2025.
//

import SwiftUI

struct CustomImage: View {
    var url: URL? = nil
    
    var body: some View {
        AsyncImage(url: url, transaction: .init(animation: .smooth)) { phase in
            if let image = phase.image {
                image.resizable() // Displays the loaded image.
                    .aspectRatio(contentMode: .fit)
            } else if phase.error != nil {
                Image(systemName: "photo.badge.exclamationmark")
                    .font(.largeTitle)
                    .foregroundStyle(.red)
            } else {
                LoadingView(.rect(cornerRadius: 16))
            }
        }
    }
}

#Preview {
    CustomImage()
}
