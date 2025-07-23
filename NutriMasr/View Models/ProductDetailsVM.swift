//
//  ProductDetailsVM.swift
//  NutriMasr
//
//  Created by Mark George on 22/06/2025.
//

import Foundation
import Supabase

@Observable class ProductDetailsVM {
    var product: Product = Constants.emptyProduct
    
    var alertTitle = ""
    var alertMessage = ""
    var showErrorAlert = false
    var isLoading = false
    var discardedValue = false
    
    /// Calculates calorie information either per serving or per 100g based on user preference.
    /// - Parameters:
    ///   - caloriesPer100g: The number of calories in 100 grams of the product.
    ///   - servingWeight: The weight of the serving in grams.
    ///   - isPerServing: If true, returns calories per serving; if false, returns calories per 100g.
    /// - Returns: The calorie amount based on the selected mode.
    func calculateCalories(_ caloriesPer100g: Double?, servingWeight: Double?, isPerServing: CustomSegmentedPickerOptions) -> Double {
        guard caloriesPer100g != nil else { print("calories don't exist"); return 0.0 }
        guard servingWeight != nil else { print("servingWeight don't exist"); return 0.0 }
        let result =  isPerServing == .serving ? (servingWeight! * caloriesPer100g!) / 100 : caloriesPer100g!
        return (result * 10).rounded() / 10
    }
    
    func handleFetchingProduct(from barcode: String) {
        isLoading = true
        Task {
            switch await fetchProduct(from: barcode) {
            case .success(let product):
                self.product = product
                isLoading = false
                await updateScanCount(id: barcode, scans: product.scans)
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
    
    func fetchProduct(from barcode: String) async -> Result<Product, SupaDatabaseErrors> {
        do {
            let products: [Product] = try await Constants.client
                .from("products")
                .select()
                .equals("id", value: barcode)
                .execute()
                .value
            
            guard let product = products.first else { return .failure(.notFound) }
            return .success(product)
        }  catch let err as PostgrestError {
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
    
    func updateScanCount(id: String, scans: Int?) async {
        guard let scans = scans else { print("no scans"); return }
        
        do {
            try await Constants.client
              .from("products")
              .update(["scans": scans + 1])
              .eq("id", value: id)
              .execute()
        } catch {
            print("error yasta ebn mtnaka \(error.localizedDescription)")
        }
    }
}
