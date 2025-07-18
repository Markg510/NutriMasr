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
    
    let apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im11Y2FtYW91a21lcGNjd3B1YmZtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTExMjY2MDgsImV4cCI6MjA2NjcwMjYwOH0.r8Cs0rML-e-z0-EPKXUf35-Q8cJ2StqYdTXnNQ5Vd8c"
    
    let secret = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im11Y2FtYW91a21lcGNjd3B1YmZtIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTEyNjYwOCwiZXhwIjoyMDY2NzAyNjA4fQ.GnfTcepW1LMfPVqSTLiCPgFoXaDvWMYKmJnef20E0fQ"
    
    lazy var client = SupabaseClient(supabaseURL: url, supabaseKey: apiKey).storage
    
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


