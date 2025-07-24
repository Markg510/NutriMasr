//
//  AppTextField.swift
//  NutriMasr
//
//  Created by Mark George on 24/07/2025.
//

import SwiftUI

struct AppTextField: View {
    let placeholder: String
    let fieldType: ProductFields?
    let causingErrorFields: Set<ProductFields>
    let ingredientsCount: Int
    var background: Color = .colorPrimary
    @Binding var text: String
    
    
    var body: some View {
        if let fieldType, causingErrorFields.contains(fieldType) {
            Text("Empty Field!")
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)
        }
        
        TextField(placeholder, text: $text)
            .padding(12)
            .background(background)
            .clipShape(.rect(cornerRadius: 16))
            .shadow(radius: 1, x: 1, y: 1)
            .padding(.bottom)
            .keyboardType({
                return switch fieldType {
                case .name, .ingredient:
                    .default
                default:
                    .numbersAndPunctuation
                }
            }())
            .submitLabel(fieldType == .ingredient(index: ingredientsCount - 1) ? .done : .next)
    }
}

#Preview {
    AppTextField(
        placeholder: "John Doe",
        fieldType: .calories,
        causingErrorFields: [],
        ingredientsCount: 0,
        text: .constant("")
    )
}
