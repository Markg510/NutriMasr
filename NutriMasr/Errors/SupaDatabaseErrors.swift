//
//  FirestoreErrors.swift
//  NutriMasr
//
//  Created by Mark George on 23/06/2025.
//

import Foundation

enum SupaDatabaseErrors: Error, Equatable {
    case noInternet
    case unauthorized        // 401
    case forbidden           // 403
    case notFound            // 404
    case alreadyExists       // 409
    case rateLimited         // 429 or "SlowDown"
    case serverError         // 500+
    case rlsViolation        // "violates row-level security"
    case unknown(String)
}
