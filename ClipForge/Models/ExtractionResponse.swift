//
//  ExtractionResponse.swift
//  ClipForge
//
//  Decodes the JSON response from POST /v1/extract.
//  Maps snake_case backend keys to camelCase Swift properties.
//

import Foundation

/// The successful response from the backend's `/v1/extract` endpoint.
///
/// After decoding, call `toVideoMetadata()` to convert into the app's
/// canonical `VideoMetadata` type for use throughout the UI and encoding layers.
struct ExtractionResponse: Decodable, Sendable {

    /// Always "success" for a 200 response.
    let status: String

    /// Detected platform (e.g., "twitter", "instagram").
    let platform: SupportedPlatform

    /// Temporary signed URL pointing to `/v1/media/{file_id}`.
    let videoURL: URL

    /// Duration of the source video in seconds.
    let duration: TimeInterval

    /// Video width in pixels.
    let width: Int

    /// Video height in pixels.
    let height: Int

    /// Video file size in bytes.
    let fileSize: Int64

    /// MIME type of the video (typically "video/mp4").
    let contentType: String

    /// Title or caption of the source post, if available.
    let title: String?

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case status
        case platform
        case videoURL    = "video_url"
        case duration
        case width
        case height
        case fileSize    = "file_size"
        case contentType = "content_type"
        case title
    }

    // MARK: - Conversion

    /// Converts this API response into the app's canonical `VideoMetadata`.
    ///
    /// Extracts the file ID from the signed media URL path to use as the
    /// video's unique identifier.
    func toVideoMetadata() -> VideoMetadata {
        // The media URL path is like /v1/media/tmp_a1b2c3d4.mp4
        // Extract the filename (without extension) as the ID.
        let fileID = videoURL.lastPathComponent
            .replacingOccurrences(of: ".mp4", with: "")

        return VideoMetadata(
            id: fileID,
            platform: platform,
            duration: duration,
            width: width,
            height: height,
            fileSize: fileSize,
            mediaURL: videoURL
        )
    }
}
