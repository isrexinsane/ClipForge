//
//  ExtractionRequest.swift
//  ClipForge
//
//  Request body for POST /v1/extract.
//

import Foundation

/// The JSON body sent to the backend's extraction endpoint.
///
/// Only the `url` field is required. The backend applies its own
/// defaults for resolution and duration limits.
struct ExtractionRequest: Encodable, Sendable {

    /// The social media URL to extract video from.
    let url: String
}
