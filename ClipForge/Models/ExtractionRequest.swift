//
//  ExtractionRequest.swift
//  ClipForge
//
//  Request body for POST /v1/extract.
//

import Foundation

/// The JSON body sent to the backend's extraction endpoint.
///
/// `url` is required. Resolution and duration have sensible defaults
/// matching the API Contract §3.1.
struct ExtractionRequest: Encodable, Sendable {

    /// The social media URL to extract video from.
    let url: String

    /// Maximum video resolution. Default: "720p".
    let maxResolution: String

    /// Maximum source video duration in seconds. Default and max: 60.
    let maxDuration: Int

    enum CodingKeys: String, CodingKey {
        case url
        case maxResolution = "max_resolution"
        case maxDuration   = "max_duration"
    }

    init(url: String, maxResolution: String = "720p", maxDuration: Int = 60) {
        self.url = url
        self.maxResolution = maxResolution
        self.maxDuration = maxDuration
    }
}
