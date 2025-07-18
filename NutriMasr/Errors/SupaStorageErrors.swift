//
//  SupaStorageErrors.swift
//  NutriMasr
//
//  Created by Mark George on 30/06/2025.
//

import Foundation

enum SupaStorageErrors: Error {
    case noInternet
    case unauthorized
    case forbidden
    case notFound
    case alreadyExists
    case tooLarge
    case unsupportedType
    case serverError
    case rlsViolation
    case rateLimited
    case unknown(String)
}
