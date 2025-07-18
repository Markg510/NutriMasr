//
//  AddProductVM.swift
//  NutriMasr
//
//  Created by Mark George on 24/06/2025.
//

import SwiftUI
import Supabase
import Network
import PhotosUI

enum ProductFields: Hashable {
    case name, weight, protein, sodium, category, sugars, fiber, fat, carbohydrates, calories
    case ingredient(index: Int)
}

@Observable class AddProductVM {
    var barcode: String? = nil
    var showScanningSheet = false
    
    var name: String = ""
    var weight: String = ""
    var protein: String = ""
    var sodium: String = ""
    var sugars: String = ""
    var fiber: String = ""
    var fat: String = ""
    var carbohydrates: String = ""
    var calories: String = ""
    var ingredients: [String] = ["", ""]
    var causingErrorFields: Set<ProductFields> = []
    var ingredientsCount = 2
    var category: Categories? = nil
    var showOptions = false
    var isFinished = false
    
    var showPickerItem = false
    var pickerItem: PhotosPickerItem? = nil
    var productImg: Image? = nil
    var photoData: Data? = nil
    
    var alertTitle = ""
    var alertMessage = ""
    var showErrorAlert = false
    var isLoading = false
    
    func handleAddingProduct() {
        Task {
            guard let product = getProduct() else { return }
            
            isLoading = true
            switch await addProductToFirestore(product) {
            case .success():
                handleAddingProductImg()
            case .failure(let err):
                alertTitle = switch err {
                case .noInternet:
                    "No Internet Connection!"
                case .unauthorized:
                    "Unauthorized Access. Please sign in again."
                case .forbidden:
                    "You don't have permission to perform this action."
                case .rlsViolation:
                    "Access blocked by security rules. Contact support if this is unexpected."
                case .alreadyExists:
                    "Product already exists!"
                case .notFound:
                    "Product not found in database."
                case .rateLimited:
                    "Too many requests! Please slow down and try again later."
                case .serverError:
                    "A server error occurred. Please try again in a moment."
                case .unknown(let errText):
                    errText
                }
                
                isLoading = false
                showErrorAlert = true
            }
        }
    }
    
    func getImageData() async {
        do {
            guard let photoItem = pickerItem else {
                alertTitle = "No Image Selected!"
                isLoading = false
                showErrorAlert = true
                return
            }

            self.photoData = try await photoItem.loadTransferable(type: Data.self)
            guard let photoData = photoData else {
                alertTitle = "No Image Selected!"
                isLoading = false
                showErrorAlert = true
                return
            }
            
            if let uiImage = UIImage(data: photoData) {
                productImg = Image(uiImage: uiImage)
            } else {
                alertTitle = "No Image Selected!"
                isLoading = false
                showErrorAlert = true
                return
            }
        } catch {
            alertTitle = "No Image Selected!"
            isLoading = false
            showErrorAlert = true
            return
        }
    }
    
    func handleAddingProductImg() {
        guard let photoData = photoData else {
            alertTitle = "No Image Selected!"
            isLoading = false
            showErrorAlert = true
            return
        }
        guard let barcode = barcode else {
            alertTitle = "Barcode Can't Be Empty"
            isLoading = false
            showErrorAlert = true
            return
        }
        
        Task {
            switch await StorageManager.shared.uploadProductImg(code: barcode, data: photoData) {
            case .success():
                isLoading = false
                isFinished = true
                
            case .failure(let err):
                switch err {
                case .noInternet:
                    alertTitle = "No Internet Connection!"
                    alertMessage = "Please check your connection"
                case .unauthorized:
                    alertTitle = "Unauthorized Access"
                    alertMessage = "Please sign in again"
                case .forbidden:
                    alertTitle = "You Don't Have Permission"
                case .rlsViolation:
                    alertTitle = "Access blocked by security rules!"
                    alertMessage = "Contact Support if this is unexpected"
                case .alreadyExists:
                    alertTitle = "File already exists!"
                case .notFound:
                    alertTitle = "File not found in storage."
                case .tooLarge:
                    alertTitle = "The file is too large to upload!"
                    alertMessage = "Please choose a smaller file"
                case .unsupportedType:
                    alertTitle = "Unsupported file type!"
                    alertMessage = "Please upload a vaild WEBP image"
                case .rateLimited:
                    alertTitle = "Too many requests!"
                    alertMessage = "Please slow down and try again later"
                case .serverError:
                    alertTitle = "A server error occurred!"
                    alertMessage = "Please try again in a moment"
                case .unknown(let errText):
                    alertTitle = errText
                }
                
                isLoading = false
                showErrorAlert = true
            }
        }
        
    }
    
    func getHint(from title: String) -> String {
        return if title == "Ingredients" || title == "Product Name" || title == "Image URL" {
            ""
        } else if title == "Calories" {
            "(per kcal)"
        } else if title == "Liters" {
            "(per Liter)"
        } else {
            "(per g)"
        }
    }
    
    func getProduct() -> Product? {
        if barcode == nil {
            alertTitle = "Barcode Can't Be Empty"
            showErrorAlert = true
            return nil
        }
        
        withAnimation {
            if name.isEmpty {
                causingErrorFields.insert(.name)
            } else {
                causingErrorFields.remove(.name)
            }
            
            if category == nil {
                causingErrorFields.insert(.category)
            } else {
                causingErrorFields.remove(.category)
            }
            
            if Double(calories) == nil {
                causingErrorFields.insert(.calories)
            } else {
                causingErrorFields.remove(.calories)
            }
            
            if Double(weight) == nil {
                causingErrorFields.insert(.weight)
            } else {
                causingErrorFields.remove(.weight)
            }
            
            if Double(protein) == nil {
                causingErrorFields.insert(.protein)
            } else {
                causingErrorFields.remove(.protein)
            }
            
            if Double(sodium) == nil {
                causingErrorFields.insert(.sodium)
            } else {
                causingErrorFields.remove(.sodium)
            }
            
            if Double(sugars) == nil {
                causingErrorFields.insert(.sugars)
            } else {
                causingErrorFields.remove(.sugars)
            }
            
            if Double(fiber) == nil {
                causingErrorFields.insert(.fiber)
            } else {
                causingErrorFields.remove(.fiber)
            }
            
            if Double(fat) == nil {
                causingErrorFields.insert(.fat)
            } else {
                causingErrorFields.remove(.fat)
            }
            
            if Double(carbohydrates) == nil {
                causingErrorFields.insert(.carbohydrates)
            } else {
                causingErrorFields.remove(.carbohydrates)
            }
        }
        
        guard causingErrorFields.isEmpty else {
            return nil
        }

        return Product(
            id: barcode,
            name: name,
            caloriesPer100g: Double(calories),
            scans: 0,
            weight: Double(weight),
            protein: Double(protein),
            sodium: Double(sodium),
            sugars: Double(sugars),
            fiber: Double(fiber),
            category: category,
            fat: Double(fat),
            carbohydrates: Double(carbohydrates),
            ingredients: ingredients
        )
    }
    
    // MARK: -- DATABASE

    func addProductToFirestore(_ product: Product) async -> Result<Void, SupaDatabaseErrors> {        
        do {
            guard await checkInternetConnectionDevice() else { return .failure(.noInternet) }
            try await Constants.client
              .from("products")
              .insert(product)
              .execute()
            
            return .success(())
        } catch let err as PostgrestError {
            switch err.code {
            case "permission_denied", "access_denied":
                return .failure(.forbidden)
                
            case "invalid_jwt", "jwt_expired", "invalid_token", "unauthorized":
                return .failure(.unauthorized)
                
            case "row_level_security_violation":
                return .failure(.rlsViolation)
                
            case "not_found":
                return .failure(.notFound)
                
            case "duplicate", "already_exists", "23505": // 23505 = PostgreSQL unique_violation
                return .failure(.alreadyExists)
                
            case "rate_limit_exceeded", "too_many_requests", "slowdown":
                return .failure(.rateLimited)
                
            case "server_error", "internal_error":
                return .failure(.serverError)
            case "anonymous_provider_disabled":
                return .failure(.unauthorized)
            default:
                return .failure(.unknown(err.message))
            }
        } catch {
            if (error as NSError).code == NSURLErrorNotConnectedToInternet {
                return .failure(.noInternet)
            }
            
            return .failure(.unknown(error.localizedDescription))
        }
    }
    
    func clearAllFields() {
        withAnimation(.snappy) {
            barcode = nil
            name = ""
            calories = ""
            category = nil
            weight = ""
            fat = ""
            carbohydrates = ""
            sodium = ""
            protein = ""
            sugars = ""
            fiber = ""
            ingredientsCount = 2
            ingredients = Array(ingredients.prefix(2))
            ingredients = ingredients.map({ _ in "" })
            isFinished = false
            pickerItem = nil
            productImg = nil
            photoData = nil
        }
    }

    func checkInternetConnectionDevice() async -> Bool {
        await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "NetworkMonitor")

            monitor.pathUpdateHandler = { path in
                monitor.cancel() // Stop monitoring after one result
                continuation.resume(returning: path.status == .satisfied)
            }

            monitor.start(queue: queue)
        }
    }
    
    func fillWithPepsiDietData() {
        withAnimation {
            barcode = "6223001360186"
            name = "Pepsi Diet"
            calories = "1"
            category = .drinks
            weight = "320"
            fat = "0"
            carbohydrates = "0"
            sodium = "12"
            protein = "0"
            sugars = "0"
            fiber = "0"
            
            // Add 6 more empty ingredients to reach total of 8
            for _ in 0..<6 {
                ingredients.append("")
                ingredientsCount += 1
            }

            ingredients[0] = "Carbonated Water"
            ingredients[1] = "Caramel Color"
            ingredients[2] = "Phosphoric Acid"
            ingredients[3] = "Aspartame"
            ingredients[4] = "Potassium Benzoate"
            ingredients[5] = "Caffeine"
            ingredients[6] = "Citric Acid"
            ingredients[7] = "Natural Flavoring"
        }
    }
}
