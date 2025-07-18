//
//  CategoryVM.swift
//  NutriMasr
//
//  Created by Mark George on 26/06/2025.
//

import SwiftUI
import Supabase

@Observable class CategoryVM {
    var isLoading = true
    var products: [Product] = []
    
    var alertTitle = ""
    var showErrorAlert = false
    
    func handleFetchingCategories(_ category: Categories) {
        Task {
            isLoading = true
            switch await fetchCategory(category) {
            case .success(let products):
                withAnimation {
                    self.products = products
                }
                
                isLoading = false
            case .failure(let err):
                print("failed \(err)")
                isLoading = false
            }
        }
    }
    
    func fetchCategory(_ category: Categories) async -> Result<[Product], SupaDatabaseErrors> {
        do {
            let products: [Product] = try await Constants.client
                .from("products")
                .select()
                .equals("category", value: category.rawValue.lowercased())
                .execute()
                .value
            
            return .success(products)
            
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
}
