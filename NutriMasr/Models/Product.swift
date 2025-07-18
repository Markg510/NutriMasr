//
//  Product.swift
//  NutriMasr
//
//  Created by Mark George on 22/06/2025.
//

import Foundation

struct Product: Identifiable, Codable, Equatable, Hashable {
    var id: String?
    let name: String?
    
    let caloriesPer100g: Double?
    let scans: Int?
    let weight: Double?
    
    let protein: Double?
    let sodium: Double?
    let sugars: Double?
    let fiber: Double?
    let category: Categories?
    
    let fat: Double?
    let carbohydrates: Double?
    
    let ingredients: [String]?
    
    func getImgURL() -> URL {
        let fileName = "\(id ?? "").webp"
        let imgBaseURL = "https://mucamaoukmepccwpubfm.supabase.co/storage/v1/object/public/product-imgs//"

        guard let url = URL(string: imgBaseURL + fileName) else {
            return URL(string: "")!
        }
        
        return url
    }
}
