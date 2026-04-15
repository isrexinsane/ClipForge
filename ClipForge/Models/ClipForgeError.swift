//
//  ClipForgeError.swift
//  ClipForge
//
//  Typed error enum for every failure state in the app.
//  Conforms to LocalizedError so SwiftUI views can display
//  errorDescription directly.
//
//  COMPLIANCE: No error message uses the word "download".
//  Use "import", "retrieve", or "process" instead.
//

import Foundation

/// Every error the app can encounter, from network failures to GIF encoding issues.
///
/// Each case provides a user-facing `errorDescription` suitable for display
/// in alerts and error screens. The networking layer maps `APIErrorResponse`
/// codes into these cases via `APIErrorResponse.toClipForgeError()`.
enum ClipForgeError: Error, LocalizedError, Sendable {

    /// The pasted text is not a valid URL.
    case invalidURL

    /// The URL's host doesn't match any supported platform.
    /// The associated value is the hostname that was rejected.
    case unsupportedPlatform(String)

    /// The source video exceeds the maximum allowed duration.
    case videoTooLong

    /// The backend failed to extract video from the given platform.
    case extractionFailed(platform: String, detail: String)

    /// The backend did not respond within the timeout window.
    case extractionTimeout

    /// The extractor for this platform is known to be broken.
    case platformUnavailable

    /// The device has no network connection.
    case networkUnavailable

    /// The backend server could not be reached.
    case serverUnreachable

    /// Missing or invalid API key.
    case unauthorized

    /// Unhandled backend server error.
    case serverError

    /// Too many requests — the user must wait before retrying.
    /// The associated value is the number of seconds to wait.
    case rateLimited(retryAfter: Int)

    /// The signed media URL token is malformed or has a signature mismatch.
    case invalidToken

    /// The signed media URL has expired (5-minute window passed).
    case mediaExpired

    /// The requested media file does not exist on the server.
    case mediaNotFound

    /// The generated GIF exceeds the maximum file size after all optimization passes.
    case fileTooLarge

    /// The GIF encoding pipeline encountered an error.
    case gifEncodingFailed(String)

    /// The user denied access to the photo library.
    case photoLibraryDenied

    /// An unexpected error not covered by other cases.
    case unknown(Error)

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "That doesn't look like a valid link. Please paste a link from a supported platform."

        case .unsupportedPlatform(let host):
            return "\(host) isn't supported yet. ClipForge works with Twitter/X, Instagram, Reddit, TikTok, and Twitch."

        case .videoTooLong:
            return "That video is too long. ClipForge supports videos up to 60 seconds."

        case .extractionFailed(let platform, let detail):
            return "Couldn't retrieve the video from \(platform). \(detail)"

        case .extractionTimeout:
            return "The request took too long. Please try again in a moment."

        case .platformUnavailable:
            return "This platform is temporarily unavailable. Please try again later."

        case .networkUnavailable:
            return "No internet connection. Please check your network and try again."

        case .serverUnreachable:
            return "ClipForge's server isn't responding. Please try again shortly."

        case .unauthorized:
            return "Unable to connect to ClipForge. Please update the app and try again."

        case .serverError:
            return "Something went wrong on our end. Please try again in a moment."

        case .rateLimited(let retryAfter):
            return "You've made too many requests. Please wait \(retryAfter) seconds before trying again."

        case .invalidToken:
            return "This video link is no longer valid. Please import the video again."

        case .mediaExpired:
            return "This video link has expired. Please import the video again."

        case .mediaNotFound:
            return "The video could not be found. Please try importing again."

        case .fileTooLarge:
            return "The GIF is too large even after optimization. Try a shorter clip or a lower quality preset."

        case .gifEncodingFailed(let detail):
            return "GIF creation failed: \(detail)"

        case .photoLibraryDenied:
            return "ClipForge needs access to your photo library to save GIFs. Please enable it in Settings."

        case .unknown:
            return "Something went wrong. Please try again."
        }
    }

    // MARK: - Retry Classification

    /// Whether this error is transient and safe to retry automatically.
    ///
    /// Per Architecture Spec §8.4: retry extractionTimeout, serverError,
    /// and networkUnavailable. Do NOT retry rateLimited — surface retryAfter
    /// to the caller instead.
    var isTransient: Bool {
        switch self {
        case .extractionTimeout, .serverError, .networkUnavailable, .serverUnreachable:
            return true
        default:
            return false
        }
    }
}
