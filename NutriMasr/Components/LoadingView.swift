//
//  LoadingView.swift
//  NutriMasr
//
//  Created by Mark George on 25/06/2025.
//

import SwiftUI

struct LoadingView<S: Shape>: View {
    var shape: S
    var color: Color
    
    init(_ shape: S, _ color: Color = .white) {
        self.shape = shape
        self.color = color
    }
    
    @State private var isAnimating: Bool = false
    var body: some View {
        shape
            .fill(color)
            // Skeleton Effect
            .overlay {
                GeometryReader {
                    let size = $0.size
                    let skeletonWidth = size.width / 2
                    // Limiting Blur Radius to radius to 30+
                    let blurRadius = max(skeletonWidth / 2, 30)
                    let blurDiameter = blurRadius * 2
                    let minX = -(skeletonWidth + blurDiameter)
                    let maxX = size.width + skeletonWidth + blurDiameter
                    
                    Rectangle()
                        .fill(Color(.systemGray3))
                        .frame(width: skeletonWidth, height: size.height * 2)
                        .frame(height: size.height)
                        .blur(radius: blurRadius)
                        .rotationEffect(.degrees(rotation))
//                        .blendMode(.softLight)
                        .offset(x: isAnimating ? maxX : minX)
                    
                    // Moving from left to right
                }
            }.clipShape(shape)
            .compositingGroup()
            .onAppear {
                guard !isAnimating else { return }
                withAnimation(animation) {
                    isAnimating = true
                }
            }.onDisappear {
                isAnimating = false
            }.transaction {
                if $0.animation != animation {
                    $0.animation = .none
                }
            }
    }
    
    var rotation: Double {
        return 5
    }
    
    var animation: Animation {
        .easeInOut(duration: 1.5).repeatForever(autoreverses: false)
    }
}

#Preview {
    LoadingView(.circle)
        .frame(width: 100, height: 100)
}
