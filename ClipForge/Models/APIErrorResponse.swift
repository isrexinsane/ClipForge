//
//  APIErrorResponse.swift
//  ClipForge
//
//  Decodes the backend's error JSON and maps error codes
//  to typed ClipForgeError cases.
//

import Foundation

/// The JSON shape returned by the backend for any non-200 response.
///
/// Example:
/// ```json
/// {
///   "status": "error",
///   "error_code": "UNSUPPORTED_PLATFORM",
///   "message": "The URL host 'youtube.com' is not in the supported platforms list.",
///   "retry_after": null
/// }
/// ```
struct APIErrorResponse: Decodable, Sendable {

    /// The error code string (e.g., "UNSUPPORTED_PLATFORM", "EXTRACTION_FAILED").
    let errorCode: String

    /// Human-readable detail message from the backend.
    let message: String

    /// Seconds to wait before retrying, if applicable (for rate limiting).
    let retryAfter: Int?

    enum CodingKeys: String, CodingKey {
        case errorCode  = "error_code"
        case message
        case retryAfter = "retry_after"
    }

    // MARK: - Mapping

    /// Converts the backend error code into the appropriate `ClipForgeError` case.
    ///
    /// Covers all 12 error codes from API Contract §4.
    func toClipForgeError() -> ClipForgeError {
        switch errorCode {
        case "INVALID_URL":
            return .invalidURL

        case "UNSUPPORTED_PLATFORM":
            return .unsupportedPlatform(message)

        case "VIDEO_TOO_LONG":
            return .videoTooLong

        case "EXTRACTION_FAILED":
            return .extractionFailed(platform: "", detail: message)

        case "EXTRACTION_TIMEOUT":
            return .extractionTimeout

        case "PLATFORM_UNAVAILABLE":
            return .platformUnavailable

        case "RATE_LIMITED":
            return .rateLimited(retryAfter: retryAfter ?? 60)

        case "UNAUTHORIZED":
            return .unauthorized

        case "SERVER_ERROR":
            return .serverError

        case "INVALID_TOKEN":
            return .invalidToken

        case "EXPIRED_MEDIA":
            return .mediaExpired

        case "MEDIA_NOT_FOUND":
            return .mediaNotFound

        default:
            return .extractionFailed(platform: "", detail: message)
        }
    }
}
