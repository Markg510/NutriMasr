//
//  StorageManager.swift
//  NutriMasr
//
//  Created by Mark George on 30/06/2025.
//

import Foundation
import Supabase

class StorageManager {
    static let shared = StorageManager()
    
    let url = URL(string: "https://mucamaoukmepccwpubfm.supabase.co")!
    
    lazy var client = SupabaseClient(supabaseURL: url, supabaseKey: Secrets.apiKey).storage
    
    func uploadProductImg(code: String, data: Data) async -> Result<Void, SupaStorageErrors> {
        let fileName = "\(code).webp"
        
        do {
            try await client
              .from("product-imgs")
              .upload(
                fileName,
                data: data,
                options: FileOptions(
                  cacheControl: "3600",
                  contentType: "image/webp",
                  upsert: false
                )
              )
                        
            return .success(())
        } catch let err as StorageError {
            switch err.error {
            case "NoSuchKey":
                return .failure(.notFound)
                
            case "AccessDenied":
                return .failure(.rlsViolation)
                
            case "EntityTooLarge", "Payload too large":
                return .failure(.tooLarge)
                
            case "InvalidMimeType":
                return .failure(.unsupportedType)
                
            case "KeyAlreadyExists", "ResourceAlreadyExists", "Duplicate":
                return .failure(.alreadyExists)
                
            case "SlowDown":
                return .failure(.rateLimited)
                
            case "DatabaseError", "InternalError":
                return .failure(.serverError)
    
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


