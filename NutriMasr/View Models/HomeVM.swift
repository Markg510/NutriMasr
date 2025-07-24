//
//  HomeVM.swift
//  NutriMasr
//
//  Created by Mark George on 11/07/2025.
//

import Foundation
import Supabase

@Observable class HomeVM {
    var mostScannedProducts: [Product] = []
    
    var hideMostScanned = false
    var alertTitle = ""
    var alertMessage = ""
    var showErrorAlert = false
    var isLoading = false
    
    var showUserNameOverlay: Bool = false
    
    func handleFetchingMostScannedProducts() {
        isLoading = true
        Task {
            switch await fetchMostScannedProducts() {
            case .success(let products):
                isLoading = false
                mostScannedProducts = products
                if products.isEmpty { hideMostScanned = true }
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
    
    func fetchMostScannedProducts() async -> Result<[Product], SupaDatabaseErrors> {
        do {
            let products: [Product] = try await Constants.client
                .from("products")
                .select()
                .gt("scans", value: 0)          // scans > 0
                .order("scans", ascending: false) // sort by scans descending
                .limit(5)                         // only top 5
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
