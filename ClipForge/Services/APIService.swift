//
//  APIService.swift
//  ClipForge
//
//  Single networking class for all backend communication.
//  Provides two async methods: extractVideo and downloadMedia.
//
//  STORY-009: APIService — Core Networking Layer
//

import Foundation

/// Handles all communication with the ClipForge backend.
///
/// - `extractVideo(url:)` sends a social media URL to the backend and
///   returns extraction metadata including a signed download URL.
/// - `downloadMedia(from:progressHandler:)` fetches the video file from
///   the signed URL and saves it locally.
///
/// Retry policy (Architecture Spec §8.4): transient errors
/// (EXTRACTION_TIMEOUT, SERVER_ERROR, networkUnavailable) are retried
/// up to 2 times with exponential backoff (2s, 4s). Non-transient
/// errors and RATE_LIMITED are never retried.
final class APIService: NSObject, Sendable {

    static let shared = APIService()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private override init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        // ExtractionResponse uses explicit CodingKeys, so no global strategy needed.
        // APIErrorResponse also uses explicit CodingKeys.

        self.encoder = JSONEncoder()

        super.init()
    }

    // MARK: - Extract Video

    /// Sends a social media URL to the backend for extraction.
    ///
    /// Retries up to 2 times with exponential backoff (2s, 4s) for
    /// transient errors. Non-transient errors throw immediately.
    ///
    /// - Parameter url: The social media URL string to extract.
    /// - Returns: The extraction response containing video metadata and signed URL.
    /// - Throws: `ClipForgeError` mapped from the backend error code.
    func extractVideo(url: String) async throws -> ExtractionResponse {
        let request = buildExtractRequest(url: url)
        let maxRetries = 2
        let backoffSeconds: [UInt64] = [2, 4]

        var lastError: ClipForgeError = .networkUnavailable

        for attempt in 0...maxRetries {
            if attempt > 0 {
                try await Task.sleep(nanoseconds: backoffSeconds[attempt - 1] * 1_000_000_000)
            }

            do {
                return try await performExtract(request: request)
            } catch let error as ClipForgeError {
                lastError = error

                // Only retry transient errors
                guard error.isTransient, attempt < maxRetries else {
                    throw error
                }
                // Continue to next attempt
            } catch {
                // URLSession errors (no network, etc.)
                let nsError = error as NSError
                if nsError.domain == NSURLErrorDomain,
                   nsError.code == NSURLErrorNotConnectedToInternet ||
                   nsError.code == NSURLErrorNetworkConnectionLost {
                    lastError = .networkUnavailable
                    if attempt < maxRetries { continue }
                    throw ClipForgeError.networkUnavailable
                }
                if nsError.domain == NSURLErrorDomain,
                   nsError.code == NSURLErrorTimedOut {
                    lastError = .extractionTimeout
                    if attempt < maxRetries { continue }
                    throw ClipForgeError.extractionTimeout
                }
                throw ClipForgeError.serverUnreachable
            }
        }

        throw lastError
    }

    // MARK: - Download Media

    /// Downloads the video file from a signed URL to the app's Caches directory.
    ///
    /// No `X-API-Key` header is needed — the signed URL authenticates itself.
    ///
    /// - Parameters:
    ///   - signedURL: The temporary signed URL from the extraction response.
    ///   - progressHandler: Called on the main actor with values from 0.0 to 1.0.
    /// - Returns: Local file URL in the Caches directory.
    /// - Throws: `ClipForgeError` if the download fails.
    func downloadMedia(
        from signedURL: URL,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        let (asyncBytes, response) = try await session.bytes(from: signedURL)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClipForgeError.serverUnreachable
        }

        // Handle error status codes from the media endpoint
        if httpResponse.statusCode != 200 {
            switch httpResponse.statusCode {
            case 403:
                throw ClipForgeError.invalidToken
            case 404:
                throw ClipForgeError.mediaNotFound
            case 410:
                throw ClipForgeError.mediaExpired
            default:
                throw ClipForgeError.serverError
            }
        }

        let expectedLength = httpResponse.expectedContentLength
        let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "unknown"
        let fileExtension = Self.fileExtension(forContentType: contentType)
        #if DEBUG
        print("APIService: Content-Type = \(contentType), using extension .\(fileExtension)")
        #endif

        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let localURL = cacheDir.appendingPathComponent("\(UUID().uuidString).\(fileExtension)")

        FileManager.default.createFile(atPath: localURL.path, contents: nil)
        let fileHandle = try FileHandle(forWritingTo: localURL)

        // Buffer writes in 64 KB chunks for reasonable I/O performance
        let bufferSize = 65_536
        var buffer = Data()
        buffer.reserveCapacity(bufferSize)
        var bytesReceived: Int64 = 0

        for try await byte in asyncBytes {
            buffer.append(byte)

            if buffer.count >= bufferSize {
                fileHandle.write(buffer)
                bytesReceived += Int64(buffer.count)
                buffer.removeAll(keepingCapacity: true)

                if expectedLength > 0 {
                    progressHandler(min(Double(bytesReceived) / Double(expectedLength), 1.0))
                }
            }
        }

        // Flush remaining bytes
        if !buffer.isEmpty {
            fileHandle.write(buffer)
            bytesReceived += Int64(buffer.count)
        }

        try fileHandle.close()
        progressHandler(1.0)

        let fileSize = (try? FileManager.default.attributesOfItem(atPath: localURL.path)[.size] as? Int64) ?? 0
        #if DEBUG
        print("APIService: saved \(fileSize) bytes to \(localURL.lastPathComponent)")
        #endif

        return localURL
    }

    // MARK: - Private Helpers

    /// Builds the URLRequest for POST /v1/extract.
    private func buildExtractRequest(url: String) -> URLRequest {
        let endpoint = Configuration.baseURL.appendingPathComponent("extract")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Configuration.apiKey, forHTTPHeaderField: "X-API-Key")

        let body = ExtractionRequest(url: url)
        request.httpBody = try? encoder.encode(body)

        return request
    }

    /// Executes a single extraction request and decodes the response.
    private func performExtract(request: URLRequest) async throws -> ExtractionResponse {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClipForgeError.serverUnreachable
        }

        // Success
        if httpResponse.statusCode == 200 {
            return try decoder.decode(ExtractionResponse.self, from: data)
        }

        // Error — decode the error response and map to ClipForgeError
        if let apiError = try? decoder.decode(APIErrorResponse.self, from: data) {
            throw apiError.toClipForgeError()
        }

        // Couldn't decode error body — fall back based on status code
        switch httpResponse.statusCode {
        case 401:
            throw ClipForgeError.unauthorized
        case 429:
            throw ClipForgeError.rateLimited(retryAfter: 60)
        case 500:
            throw ClipForgeError.serverError
        case 502:
            throw ClipForgeError.extractionFailed(platform: "", detail: "Service temporarily unavailable.")
        case 504:
            throw ClipForgeError.extractionTimeout
        default:
            throw ClipForgeError.serverError
        }
    }

    /// Maps a Content-Type MIME string to a file extension AVPlayer can use.
    ///
    /// AVFoundation relies on the file extension to select the correct
    /// demuxer. A mismatch (e.g., WebM bytes in a .mp4 file) causes
    /// error -12864 (AVErrorFileFormatNotRecognized).
    private static func fileExtension(forContentType contentType: String) -> String {
        // Content-Type may include charset or params: "video/mp4; charset=utf-8"
        let mime = contentType.split(separator: ";").first?
            .trimmingCharacters(in: .whitespaces).lowercased() ?? ""

        switch mime {
        case "video/mp4":                       return "mp4"
        case "video/quicktime":                 return "mov"
        case "video/x-m4v", "video/x-mp4":     return "m4v"
        case "video/webm":                      return "webm"
        case "video/x-matroska":                return "mkv"
        case "video/3gpp":                      return "3gp"
        case "video/mpeg":                      return "mpg"
        case "application/octet-stream":        return "mp4"  // Generic binary — assume mp4, best guess
        default:                                return "mp4"  // Fallback
        }
    }
}
