//
//  QualityPreset.swift
//  ClipForge
//
//  GIF encoding quality presets. Each preset maps to a set of
//  encoding parameters (dimensions, frame rate, file size target)
//  documented in CLAUDE.md § GIF Encoding Parameters.
//

import Foundation

/// Quality tiers for GIF encoding.
///
/// The `highQuality` preset is gated behind premium in the UI (Epic 7),
/// but the model itself carries no gating logic — that's the UI layer's job.
enum QualityPreset: String, Codable, CaseIterable, Sendable {
    case standard
    case discord
    case highQuality

    /// Human-friendly label for the preset picker.
    var displayName: String {
        switch self {
        case .standard:    return "Standard"
        case .discord:     return "Discord"
        case .highQuality: return "High Quality"
        }
    }

    /// Maximum output width in pixels. Height scales proportionally.
    var maxWidth: Int {
        switch self {
        case .standard:    return 480
        case .discord:     return 640
        case .highQuality: return 720
        }
    }

    /// Frames per second for the output GIF.
    var frameRate: Int {
        switch self {
        case .standard:    return 12
        case .discord:     return 15
        case .highQuality: return 20
        }
    }

    /// Target maximum file size in megabytes.
    var targetFileSizeMB: Double {
        switch self {
        case .standard:    return 5.0
        case .discord:     return 10.0
        case .highQuality: return 25.0
        }
    }
}
