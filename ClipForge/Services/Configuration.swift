//
//  Configuration.swift
//  ClipForge
//
//  Backend connection settings.
//  API key is injected at build time via Secrets.xcconfig → Info.plist.
//  See ClipForge/Config/Secrets.xcconfig.example for setup instructions.
//

import Foundation

/// Central configuration for backend API connectivity.
///
/// The API key is read from Info.plist at runtime. Info.plist references
/// the build setting `$(CLIPFORGE_API_KEY)`, which is defined in
/// `ClipForge/Config/Secrets.xcconfig` (gitignored — never committed).
enum Configuration {

    /// Base URL for the ClipForge backend API (no trailing slash).
    static let baseURL = URL(string: "https://clipforge-production-f27b.up.railway.app/v1")!

    /// API key sent in the `X-API-Key` header on every authenticated request.
    /// Loaded from Info.plist → `CLIPFORGE_API_KEY` build setting.
    static let apiKey: String = {
        // First check environment (CI, test harness, Xcode scheme override)
        if let envKey = ProcessInfo.processInfo.environment["CLIPFORGE_API_KEY"],
           !envKey.isEmpty {
            return envKey
        }

        // Primary path: read from Info.plist (injected from Secrets.xcconfig)
        if let key = Bundle.main.infoDictionary?["CLIPFORGE_API_KEY"] as? String,
           !key.isEmpty,
           key != "your_api_key_here" {
            #if DEBUG
            print("[Configuration] API key loaded: \(key.prefix(10))...")
            #endif
            return key
        }

        #if DEBUG
        fatalError(
            "CLIPFORGE_API_KEY not set. " +
            "Copy ClipForge/Config/Secrets.xcconfig.example to Secrets.xcconfig " +
            "and add your API key."
        )
        #else
        return ""
        #endif
    }()
}
