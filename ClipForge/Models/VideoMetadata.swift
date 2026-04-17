//
//  VideoMetadata.swift
//  ClipForge
//
//  App-internal representation of an imported video.
//  Created from an ExtractionResponse after a successful API call.
//

import Foundation

/// Metadata describing an imported video that is ready for trimming and GIF creation.
///
/// This is the app's canonical video type — once the networking layer decodes
/// the API response, everything downstream works with `VideoMetadata`.
struct VideoMetadata: Codable, Identifiable, Sendable {

    /// Unique identifier for this video (matches the backend's file ID).
    let id: String

    /// The social media platform this video was imported from.
    let platform: SupportedPlatform

    /// Duration of the source video in seconds.
    let duration: TimeInterval

    /// Video width in pixels.
    let width: Int

    /// Video height in pixels.
    let height: Int

    /// File size in bytes. `nil` for Instagram (RapidAPI doesn't provide this).
    let fileSize: Int64?

    /// Temporary signed URL for retrieving the video file from `/v1/media/{file_id}`.
    /// Valid for 5 minutes after extraction.
    let mediaURL: URL
}
