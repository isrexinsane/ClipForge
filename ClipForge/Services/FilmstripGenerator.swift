//
//  FilmstripGenerator.swift
//  ClipForge
//
//  Extracts evenly-spaced frame thumbnails from a video asset
//  for display in the trim bar filmstrip. Publishes frames
//  progressively as they become available.
//
//  STORY-015: Filmstrip Thumbnail Generator
//

import AVFoundation
import UIKit

/// Generates filmstrip thumbnail images from a video asset.
///
/// Thumbnails are extracted at evenly-spaced timestamps using
/// `AVAssetImageGenerator`. Frames publish progressively into
/// the `thumbnails` array — the UI updates as each frame arrives.
///
/// Memory footprint: 8–10 thumbnails at ~44×44pt ≈ 50 KB total.
@MainActor
final class FilmstripGenerator: ObservableObject {

    /// Progressively populated array of thumbnail images.
    @Published private(set) var thumbnails: [UIImage] = []

    /// Whether generation is currently in progress.
    @Published private(set) var isGenerating: Bool = false

    private var generationTask: Task<Void, Never>?

    /// Generates evenly-spaced thumbnails from the given asset.
    ///
    /// Cancels any in-progress generation before starting.
    /// Thumbnails publish one by one into the `thumbnails` array.
    ///
    /// - Parameters:
    ///   - asset: The video asset to extract frames from.
    ///   - count: Number of thumbnails to generate (default: 10).
    ///   - targetHeight: Height in points for each thumbnail (default: 44).
    func generate(from asset: AVURLAsset, count: Int = 10, targetHeight: CGFloat = 44) {
        // Cancel previous generation
        generationTask?.cancel()
        thumbnails = []
        isGenerating = true

        generationTask = Task {
            await performGeneration(asset: asset, count: count, targetHeight: targetHeight)
            isGenerating = false
        }
    }

    /// Cancels any in-progress generation.
    func cancel() {
        generationTask?.cancel()
        isGenerating = false
    }

    // MARK: - Private

    private func performGeneration(
        asset: AVURLAsset,
        count: Int,
        targetHeight: CGFloat
    ) async {
        // Load duration
        let duration: CMTime
        do {
            duration = try await asset.load(.duration)
        } catch {
            return
        }

        let totalSeconds = CMTimeGetSeconds(duration)
        guard totalSeconds > 0, count > 0 else { return }

        // Calculate evenly-spaced timestamps
        let interval = totalSeconds / Double(count)
        let times = (0..<count).map { index in
            CMTime(seconds: interval * Double(index) + interval / 2.0, preferredTimescale: 600)
        }

        // Configure generator
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        // Speed over accuracy — 0.1s tolerance for thumbnails
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.1, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.1, preferredTimescale: 600)

        // Scale to target size (3x for Retina, maintaining aspect ratio)
        let scale = UIScreen.main.scale
        let maxPixelHeight = targetHeight * scale
        generator.maximumSize = CGSize(width: 0, height: maxPixelHeight)

        // Generate frames progressively
        for time in times {
            guard !Task.isCancelled else { return }

            do {
                let (cgImage, _) = try await generator.image(at: time)
                let thumbnail = UIImage(cgImage: cgImage)
                thumbnails.append(thumbnail)
            } catch {
                // Skip failed frames — don't block the filmstrip
                continue
            }
        }
    }
}
