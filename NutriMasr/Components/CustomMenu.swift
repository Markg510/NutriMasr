//
//  CustomMenu.swift
//  NutriMasr
//
//  Created by Mark George on 25/06/2025.
//

import SwiftUI

struct CustomMenu: View {
    @Binding var showOptions: Bool
    @Binding var selected: Categories?
    
    var body: some View {
        GeometryReader {
            VStack(spacing: 0) {
                HStack {
                    Text(selected != nil ? String(describing: selected!).capitalized : "Select")
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundStyle(.colorTextTertiary)
                        .rotationEffect(.degrees(showOptions ? 180 : 0))
                }.padding(12)
                    .foregroundStyle(selected != nil ? .colorTextPrimary : .colorTextTertiary)
                    .contentShape(.rect)
                    .zIndex(10)
                    .onTapGesture {
                        withAnimation(.snappy) {
                            showOptions.toggle()
                        }
                    }
                
                if showOptions {
                    optionsMenu()
                }
            }.background(.colorPrimary)
                .clipShape(.rect(cornerRadius: 16))
                .shadow(radius: 2, x: 1, y: 1)
                .padding(.bottom)
                .frame(height: $0.size.height, alignment: .top)
                
        }
    }
    
    @ViewBuilder
    func optionsMenu() -> some View {
        VStack(spacing: 8) {
            ForEach(Categories.allCases, id: \.self) { category in
                HStack {
                    Text(String(describing: category).capitalized)
                    
                    Spacer()
                    
                    if selected == category {
                        Image(systemName: "checkmark")
                    }
                }.foregroundStyle(selected == category ? .colorTextPrimary : .colorTextTertiary)
                    .padding(.horizontal)
                    .contentShape(.rect)
                    .onTapGesture {
                        selected = category
                        withAnimation(.snappy) {
                            showOptions.toggle()
                        }
                    }
            }
        }.padding(.bottom)
    }
}

#Preview {
    AddProductView()
}
