//
//  Constants.swift
//  NutriMasr
//
//  Created by Mark George on 22/06/2025.
//

import Foundation
import Supabase

struct Constants {
    static let client = SupabaseClient(supabaseURL: URL(string: "https://mucamaoukmepccwpubfm.supabase.co")!, supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im11Y2FtYW91a21lcGNjd3B1YmZtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTExMjY2MDgsImV4cCI6MjA2NjcwMjYwOH0.r8Cs0rML-e-z0-EPKXUf35-Q8cJ2StqYdTXnNQ5Vd8c")
    
    static let sampleProduct = Product(
        id: "12345678",
        name: "Molto Magnum",
        caloriesPer100g: 463,
        scans: 0,
        weight: 50,
        protein: 7.4,
        sodium: 35,
        sugars: 234,
        fiber: 23,
        category: .sweets,
        fat: 13,
        carbohydrates: 48,
        ingredients: ["Water", "Sugar", "Corn Syrup", "Vegetable Oil", "Whey Protein Isolate"]
    )
    
    static let emptyProduct = Product(
        name: "",
        caloriesPer100g: 0,
        scans: 0,
        weight: 0,
        protein: 0,
        sodium: 0,
        sugars: 0,
        fiber: 0,
        category: .drinks,
        fat: 0,
        carbohydrates: 0,
        ingredients: []
    )
}
