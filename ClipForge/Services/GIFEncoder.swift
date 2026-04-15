//
//  GIFEncoder.swift
//  ClipForge
//
//  Core GIF encoding engine. Extracts frames from a trimmed video
//  segment using AVAssetImageGenerator, scales them, and assembles
//  an animated GIF via ImageIO (CGImageDestination).
//
//  Native only — no third-party GIF libraries.
//
//  STORY-019: GIFEncoder — Core Frame Extraction and Encoding Pipeline
//

import AVFoundation
import ImageIO
import CoreGraphics
import UIKit

/// Encoding parameters derived from the "Works Everywhere" spec.
struct GIFEncodingParams {
    let fps: Double
    let maxWidth: CGFloat

    /// Selects parameters based on clip duration.
    /// - ≤10s: 15 FPS, 640px
    /// - >10s: 12 FPS, 480px
    /// - >20s: 10 FPS, 400px
    static func forDuration(_ seconds: Double) -> GIFEncodingParams {
        if seconds > 20 {
            return GIFEncodingParams(fps: 10, maxWidth: 400)
        } else if seconds > 10 {
            return GIFEncodingParams(fps: 12, maxWidth: 480)
        } else {
            return GIFEncodingParams(fps: 15, maxWidth: 640)
        }
    }

    /// Reduced parameters for the second pass (FPS -30%, width -20%).
    func reduced() -> GIFEncodingParams {
        GIFEncodingParams(
            fps: (fps * 0.7).rounded(),
            maxWidth: (maxWidth * 0.8).rounded()
        )
    }
}

/// Result of a GIF encoding operation.
struct GIFEncodingResult {
    /// Raw GIF data.
    let data: Data
    /// Pixel dimensions of the output GIF.
    let dimensions: CGSize
    /// Whether the output exceeds the 8 MB target.
    let isOversized: Bool
}

/// Encodes trimmed video segments into animated GIFs using native ImageIO.
///
/// Usage:
/// ```swift
/// let result = try await GIFEncoder.encode(
///     asset: asset,
///     timeRange: range,
///     progressHandler: { progress in ... }
/// )
/// ```
enum GIFEncoder {

    /// Maximum target file size in bytes (8 MB).
    static let targetMaxSize: Int = 8 * 1024 * 1024

    /// Frames processed per batch before releasing memory.
    private static let batchSize = 20

    /// Encodes a trimmed video segment into an animated GIF.
    ///
    /// Attempts encoding at the "Works Everywhere" parameters first.
    /// If the result exceeds 8 MB, re-encodes with reduced parameters.
    /// If still over, returns the GIF anyway with `isOversized = true`.
    ///
    /// - Parameters:
    ///   - asset: The source video asset.
    ///   - timeRange: The trim range to encode.
    ///   - isPremium: If false, a "CLIPFORGE" watermark is composited on each frame.
    ///   - isCancelled: Closure checked between batches. Return `true` to abort.
    ///   - progressHandler: Called with values from 0.0 to 1.0.
    /// - Returns: `GIFEncodingResult` containing GIF data, dimensions, and oversize flag.
    static func encode(
        asset: AVURLAsset,
        timeRange: CMTimeRange,
        isPremium: Bool = false,
        isCancelled: @escaping () -> Bool = { false },
        progressHandler: @escaping (Double) -> Void
    ) async throws -> GIFEncodingResult {
        let duration = CMTimeGetSeconds(timeRange.duration)
        let params = GIFEncodingParams.forDuration(duration)

        // Pass 1: standard parameters
        let result = try await performEncode(
            asset: asset,
            timeRange: timeRange,
            params: params,
            isPremium: isPremium,
            isCancelled: isCancelled,
            progressHandler: { progressHandler($0 * 0.9) } // 0–90% for pass 1
        )

        if result.data.count <= targetMaxSize {
            progressHandler(1.0)
            return result
        }

        // Pass 2: reduced parameters
        let reducedParams = params.reduced()
        let pass2Result = try await performEncode(
            asset: asset,
            timeRange: timeRange,
            params: reducedParams,
            isPremium: isPremium,
            isCancelled: isCancelled,
            progressHandler: { progressHandler(0.9 + $0 * 0.1) } // 90–100% for pass 2
        )

        progressHandler(1.0)

        return GIFEncodingResult(
            data: pass2Result.data,
            dimensions: pass2Result.dimensions,
            isOversized: pass2Result.data.count > targetMaxSize
        )
    }

    // MARK: - Private

    /// Performs a single encoding pass with the given parameters.
    private static func performEncode(
        asset: AVURLAsset,
        timeRange: CMTimeRange,
        params: GIFEncodingParams,
        isPremium: Bool,
        isCancelled: @escaping () -> Bool,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> GIFEncodingResult {
        let duration = CMTimeGetSeconds(timeRange.duration)
        let totalFrames = Int(duration * params.fps)
        guard totalFrames > 0 else {
            throw ClipForgeError.gifEncodingFailed("No frames to encode.")
        }

        // Generate frame timestamps
        let frameInterval = duration / Double(totalFrames)
        let startSeconds = CMTimeGetSeconds(timeRange.start)
        let timestamps = (0..<totalFrames).map { index in
            CMTime(seconds: startSeconds + Double(index) * frameInterval, preferredTimescale: 600)
        }

        // Configure image generator
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        // Prepare GIF destination
        let gifData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            gifData as CFMutableData,
            "com.compuserve.gif" as CFString,
            totalFrames,
            nil
        ) else {
            throw ClipForgeError.gifEncodingFailed("Could not create GIF destination.")
        }

        // Global GIF properties: infinite loop
        let gifProperties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFLoopCount as String: 0
            ]
        ]
        CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)

        // Per-frame properties
        let frameDelay = 1.0 / params.fps
        let frameProperties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFDelayTime as String: frameDelay
            ]
        ]

        // Track actual dimensions from first scaled frame
        var outputDimensions = CGSize.zero

        // Process in batches
        var framesProcessed = 0
        for batchStart in stride(from: 0, to: totalFrames, by: batchSize) {
            // Check cancellation between batches
            if isCancelled() {
                throw ClipForgeError.gifEncodingFailed("Encoding cancelled.")
            }

            let batchEnd = min(batchStart + batchSize, totalFrames)
            let batchTimestamps = Array(timestamps[batchStart..<batchEnd])

            // Extract and process batch
            for timestamp in batchTimestamps {
                do {
                    let (cgImage, _) = try await generator.image(at: timestamp)
                    let scaled = scaleImage(cgImage, maxWidth: params.maxWidth)
                    let frame = isPremium ? scaled : applyWatermark(to: scaled)

                    if outputDimensions == .zero {
                        outputDimensions = CGSize(
                            width: CGFloat(frame.width),
                            height: CGFloat(frame.height)
                        )
                    }

                    CGImageDestinationAddImage(destination, frame, frameProperties as CFDictionary)
                } catch {
                    // Skip failed frames rather than aborting the entire GIF
                    continue
                }

                framesProcessed += 1
                progressHandler(Double(framesProcessed) / Double(totalFrames))
            }
            // Batch boundary — autoreleased CGImages from this batch are eligible for collection
        }

        // Finalize
        guard CGImageDestinationFinalize(destination) else {
            throw ClipForgeError.gifEncodingFailed("Failed to finalize GIF.")
        }

        let data = gifData as Data
        return GIFEncodingResult(
            data: data,
            dimensions: outputDimensions,
            isOversized: data.count > targetMaxSize
        )
    }

    // MARK: - Watermark (STORY-7.2)

    /// Composites a "CLIPFORGE" text watermark in the bottom-right corner.
    /// White text at 50% opacity with a dark shadow for legibility on any background.
    /// Font size is ~12% of frame width. Padding is 8px from edges.
    private static func applyWatermark(to image: CGImage) -> CGImage {
        let width = image.width
        let height = image.height

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else {
            return image
        }

        // Draw the original frame
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(image, in: rect)

        // Configure watermark text
        let text = "CLIPFORGE" as NSString
        let fontSize = CGFloat(width) * 0.12
        let padding: CGFloat = 8

        // Use a bold system font — JetBrains Mono may not be available
        // outside UIKit context, so we use the system monospace bold.
        let font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .bold)
        let shadow = NSShadow()
        shadow.shadowColor = UIColor.black.withAlphaComponent(0.6)
        shadow.shadowOffset = CGSize(width: 1, height: -1)
        shadow.shadowBlurRadius = 2

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white.withAlphaComponent(0.5),
            .shadow: shadow
        ]

        let textSize = text.size(withAttributes: attributes)

        // Position: bottom-right with padding.
        // CoreGraphics origin is bottom-left, so y = padding puts text at bottom.
        let x = CGFloat(width) - textSize.width - padding
        let y = padding

        // Push UIKit graphics context to draw attributed string
        UIGraphicsPushContext(context)
        // Flip coordinate system for text drawing (UIKit expects top-left origin)
        context.saveGState()
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)

        // In flipped coords, bottom-right becomes: x stays, y = height - padding - textSize.height
        let drawPoint = CGPoint(x: x, y: CGFloat(height) - padding - textSize.height)
        text.draw(at: drawPoint, withAttributes: attributes)

        context.restoreGState()
        UIGraphicsPopContext()

        return context.makeImage() ?? image
    }

    /// Scales a CGImage to fit within maxWidth, preserving aspect ratio.
    /// If the image is already smaller than maxWidth, returns it unchanged.
    private static func scaleImage(_ image: CGImage, maxWidth: CGFloat) -> CGImage {
        let originalWidth = CGFloat(image.width)
        let originalHeight = CGFloat(image.height)

        guard originalWidth > maxWidth else { return image }

        let scale = maxWidth / originalWidth
        let newWidth = Int(originalWidth * scale)
        let newHeight = Int(originalHeight * scale)

        guard let context = CGContext(
            data: nil,
            width: newWidth,
            height: newHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else {
            return image // Return original if context creation fails
        }

        context.interpolationQuality = .medium
        context.draw(image, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))

        return context.makeImage() ?? image
    }
}
