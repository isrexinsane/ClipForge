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
    case tiktok
    case twitch

    // MARK: - Display

    /// Human-friendly name shown in the UI.
    var displayName: String {
        switch self {
        case .twitter:   return "Twitter/X"
        case .instagram: return "Instagram"
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
            return ["twitter.com", "www.twitter.com", "x.com", "www.x.com", "mobile.twitter.com", "m.twitter.com"]
        case .instagram:
            return ["instagram.com", "www.instagram.com", "m.instagram.com"]
        case .tiktok:
            return ["tiktok.com", "www.tiktok.com", "m.tiktok.com", "vm.tiktok.com"]
        case .twitch:
            return ["twitch.tv", "www.twitch.tv", "clips.twitch.tv", "m.twitch.tv"]
        }
    }

    // MARK: - Path Patterns

    /// Regex patterns that validate the URL path for this platform.
    /// If any pattern matches the URL's path, the URL is considered valid
    /// for this platform. An empty array means any path is accepted
    /// (used for shortlink domains like t.co and vm.tiktok.com).
    var pathPatterns: [String] {
        switch self {
        case .twitter:
            // /user/status/1234, or shortlink (t.co has no path validation)
            return [
                #"^/[^/]+/status/\d+"#,  // twitter.com/{user}/status/{id}
                #"^/[A-Za-z0-9]+"#       // t.co/{shortcode}
            ]
        case .instagram:
            return [
                #"^/(reel|p)/[^/]+"#,              // /reel/{id} or /p/{id}
                #"^/stories/[^/]+/\d+"#             // /stories/{user}/{id}
            ]
        case .tiktok:
            return [
                #"^/@[^/]+/video/\d+"#,             // /@{user}/video/{id}
                #"^/t/[^/]+"#,                      // /t/{shortcode}
                #"^/[A-Za-z0-9]+"#                  // vm.tiktok.com/{shortcode}
            ]
        case .twitch:
            return [
                #"^/[^/]+/clip/[^/]+"#,             // /{channel}/clip/{slug}
                #"^/[A-Za-z0-9]"#                   // clips.twitch.tv/{slug}
            ]
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

    /// Returns the platform for a full URL, validating both host and path.
    /// Returns `nil` if the host is unrecognized or the path doesn't match
    /// any expected pattern for the detected platform.
    static func platform(forURL url: URL) -> SupportedPlatform? {
        guard let host = url.host?.lowercased(),
              let platform = platform(forHost: host) else {
            return nil
        }

        let path = url.path
        // Shortlink domains accept any path
        let shortlinkHosts = ["t.co", "vm.tiktok.com"]
        if shortlinkHosts.contains(host) && !path.isEmpty && path != "/" {
            return platform
        }

        // Validate path against platform patterns
        return platform.pathPatterns.contains { pattern in
            path.range(of: pattern, options: .regularExpression) != nil
        } ? platform : nil
    }

    // MARK: - YouTube Detection

    /// Hostnames that identify a YouTube URL. Detected and rejected in the MVP.
    static let youTubeHosts: Set<String> = [
        "youtube.com", "www.youtube.com", "m.youtube.com",
        "youtu.be", "music.youtube.com"
    ]

    /// Returns `true` if the given URL belongs to YouTube.
    static func isYouTubeURL(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return youTubeHosts.contains(host)
    }

    // MARK: - Reddit Detection

    /// Hostnames that identify a Reddit URL. Removed from MVP — extraction
    /// unreliable via proxy. Reddit URLs return UNSUPPORTED_PLATFORM.
    static let redditHosts: Set<String> = [
        "reddit.com", "www.reddit.com", "old.reddit.com",
        "v.redd.it", "m.reddit.com"
    ]

    /// Returns `true` if the given URL belongs to Reddit.
    static func isRedditURL(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return redditHosts.contains(host)
    }
}
