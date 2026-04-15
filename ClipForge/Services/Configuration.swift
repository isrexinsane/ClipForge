//
//  Configuration.swift
//  ClipForge
//
//  Backend connection settings.
//  TODO: Move API key to xcconfig for build-time injection.
//

import Foundation

/// Central configuration for backend API connectivity.
///
/// Reads the API key from the environment when available,
/// falling back to a hardcoded development key.
enum Configuration {

    /// Base URL for the ClipForge backend API (no trailing slash).
    static let baseURL = URL(string: "https://clipforge-production-f27b.up.railway.app/v1")!

    /// API key sent in the `X-API-Key` header on every authenticated request.
    static let apiKey: String = {
        if let key = ProcessInfo.processInfo.environment["CLIPFORGE_API_KEY"], !key.isEmpty {
            return key
        }
        // TODO: move to xcconfig
        return "cf_staging_d5c9a33987058b42bc93d2eab974346c91ada1b69392facf"
    }()
}
