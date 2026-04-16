//
//  ImportState.swift
//  ClipForge
//
//  The import pipeline state machine. Drives CTA button appearance,
//  label text, and Trim Modal presentation.
//
//  Extracted from HomeViewModel.swift so all files that reference
//  ImportState compile independently.
//
//  STORY-011: HomeViewModel — Import Flow Orchestration
//

import Foundation

/// The import pipeline state machine. Drives all CTA button appearance
/// and Trim Modal presentation from a single published property.
enum ImportState: Equatable {
    case idle
    case urlDetected(url: URL, platform: String)
    case youtubeDetected
    case redditDetected
    case extracting
    case downloading(progress: Double)
    case success(localVideoURL: URL, metadata: VideoMetadata)
    case error(message: String)

    // Equatable conformance for states with associated values
    static func == (lhs: ImportState, rhs: ImportState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case let (.urlDetected(lURL, lPlatform), .urlDetected(rURL, rPlatform)):
            return lURL == rURL && lPlatform == rPlatform
        case (.youtubeDetected, .youtubeDetected):
            return true
        case (.redditDetected, .redditDetected):
            return true
        case (.extracting, .extracting):
            return true
        case let (.downloading(lProgress), .downloading(rProgress)):
            return lProgress == rProgress
        case let (.success(lURL, lMeta), .success(rURL, rMeta)):
            return lURL == rURL && lMeta.id == rMeta.id
        case let (.error(lMsg), .error(rMsg)):
            return lMsg == rMsg
        default:
            return false
        }
    }
}
