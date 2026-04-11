//
//  SupportedPlatform.swift
//  ClipForge
//
//  Enumerates the social media platforms supported by ClipForge's
//  backend extraction service. Each case carries the hostnames used
//  to identify URLs belonging to that platform.
//

import Foundation

/// Platforms whose video content can be imported into ClipForge.
///
/// The cases match the `platform` field returned by `POST /v1/extract`.
/// YouTube is intentionally excluded from the MVP — see CLAUDE.md
/// § Supported Platforms for rationale.
enum SupportedPlatform: String, Codable, CaseIterable, Sendable {
    case twitter
    case instagram
    case reddit
    case tiktok
    case twitch

    // MARK: - Display

    /// Human-friendly name shown in the UI.
    var displayName: String {
        switch self {
        case .twitter:   return "Twitter/X"
        case .instagram: return "Instagram"
        case .reddit:    return "Reddit"
        case .tiktok:    return "TikTok"
        case .twitch:    return "Twitch"
        }
    }

    // MARK: - URL Matching

    /// Hostnames that identify a URL as belonging to this platform.
    /// Used by the clipboard monitor to detect supported links.
    /// Matching is exact string comparison on the URL's `host` component.
    var hostPatterns: [String] {
        switch self {
        case .twitter:
            return ["twitter.com", "x.com", "mobile.twitter.com", "m.twitter.com"]
        case .instagram:
            return ["instagram.com", "www.instagram.com", "m.instagram.com"]
        case .reddit:
            return ["reddit.com", "www.reddit.com", "old.reddit.com", "v.redd.it"]
        case .tiktok:
            return ["tiktok.com", "www.tiktok.com", "m.tiktok.com", "vm.tiktok.com"]
        case .twitch:
            return ["twitch.tv", "www.twitch.tv", "clips.twitch.tv", "m.twitch.tv"]
        }
    }

    // MARK: - Lookup

    /// Returns the platform matching a given hostname, or `nil` if unsupported.
    static func platform(forHost host: String) -> SupportedPlatform? {
        let normalizedHost = host.lowercased()
        return allCases.first { platform in
            platform.hostPatterns.contains(normalizedHost)
        }
    }
}
