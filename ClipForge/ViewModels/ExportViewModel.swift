//
//  ExportViewModel.swift
//  ClipForge
//
//  Orchestrates the GIF encoding pipeline: encoding → size check →
//  camera roll save → success/error state. Drives the in-modal
//  progress ring and export success UI.
//
//  STORY-020: ExportViewModel — Encoding Orchestration and Progress State
//

import AVFoundation
import Combine

/// State machine for the export pipeline.
enum ExportState: Equatable {
    case idle
    case encoding(progress: Double)
    case saving
    case success(gifData: Data, fileSize: Int, dimensions: CGSize)
    case error(String)

    static func == (lhs: ExportState, rhs: ExportState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case let (.encoding(l), .encoding(r)): return l == r
        case (.saving, .saving): return true
        case let (.success(_, lSize, lDim), .success(_, rSize, rDim)):
            return lSize == rSize && lDim == rDim
        case let (.error(l), .error(r)): return l == r
        default: return false
        }
    }
}

/// Drives the encoding → save → success flow from the CREATE button tap.
///
/// Integrates GIFEncoder for encoding and ExportManager (STORY-021) for
/// camera roll save. Published state powers the in-modal progress ring,
/// percentage text, and success/error UI.
@MainActor
final class ExportViewModel: ObservableObject {

    // MARK: - Published State

    @Published var exportState: ExportState = .idle

    /// Set when GIF exceeds 8 MB target. Contains human-readable size string.
    @Published var oversizeWarning: String?

    // MARK: - Private

    private var encodingTask: Task<Void, Never>?
    private var isCancelled = false

    // MARK: - Encoding Flow

    /// Starts the full export pipeline: encode → save → success.
    ///
    /// - Parameters:
    ///   - asset: The source video asset.
    ///   - startTime: Trim start in seconds.
    ///   - endTime: Trim end in seconds.
    ///   - isPremium: Whether the user is a premium subscriber. Controls watermark.
    func startExport(asset: AVURLAsset, startTime: Double, endTime: Double, isPremium: Bool = false) {
        guard case .idle = exportState else { return }

        isCancelled = false
        oversizeWarning = nil
        exportState = .encoding(progress: 0.0)

        let start = CMTime(seconds: startTime, preferredTimescale: 600)
        let duration = CMTime(seconds: endTime - startTime, preferredTimescale: 600)
        let timeRange = CMTimeRange(start: start, duration: duration)

        encodingTask = Task {
            await performExport(asset: asset, timeRange: timeRange, isPremium: isPremium)
        }
    }

    /// Cancels an in-progress encoding. Returns to idle.
    func cancelExport() {
        isCancelled = true
        encodingTask?.cancel()
        exportState = .idle
    }

    /// Resets from error state for retry.
    func resetToIdle() {
        exportState = .idle
        oversizeWarning = nil
    }

    // MARK: - Private

    private func performExport(asset: AVURLAsset, timeRange: CMTimeRange, isPremium: Bool = false) async {
        // Phase 1: Encode
        let result: GIFEncodingResult
        do {
            result = try await GIFEncoder.encode(
                asset: asset,
                timeRange: timeRange,
                isPremium: isPremium,
                isCancelled: { [weak self] in self?.isCancelled ?? true },
                progressHandler: { [weak self] progress in
                    Task { @MainActor in
                        guard let self, case .encoding = self.exportState else { return }
                        self.exportState = .encoding(progress: progress)
                    }
                }
            )
        } catch {
            if isCancelled { return } // Cancelled — don't show error
            exportState = .error("Something went wrong creating the GIF. Try a shorter clip.")
            return
        }

        guard !isCancelled else { return }

        // Check oversize
        if result.isOversized {
            let mbSize = String(format: "%.1f", Double(result.data.count) / 1_048_576.0)
            oversizeWarning = "This GIF is \(mbSize) MB — larger than the 8 MB target. It may not work on all platforms."
        }

        // Phase 2: Save to camera roll
        exportState = .saving

        do {
            let identifier = try await ExportManager.saveGIFToPhotos(result.data)

            // Record in GIF history for Media Library
            let entry = GIFHistoryEntry(
                id: UUID(),
                createdAt: Date(),
                fileSize: result.data.count,
                width: Int(result.dimensions.width),
                height: Int(result.dimensions.height),
                localAssetIdentifier: identifier
            )
            GIFHistoryStore.shared.addEntry(entry)

            // Consume one daily free export (no-op if premium)
            FreemiumGatekeeper.shared.incrementExportCount()

            exportState = .success(
                gifData: result.data,
                fileSize: result.data.count,
                dimensions: result.dimensions
            )
        } catch let error as ClipForgeError {
            exportState = .error(error.errorDescription ?? "Could not save GIF. Please try again.")
        } catch {
            exportState = .error("Could not save GIF. Please try again.")
        }
    }

    // MARK: - Display Helpers

    /// Formatted file size string (e.g., "3.2 MB").
    var fileSizeText: String? {
        guard case .success(_, let fileSize, _) = exportState else { return nil }
        let mb = Double(fileSize) / 1_048_576.0
        if mb >= 1.0 {
            return String(format: "%.1f MB", mb)
        } else {
            let kb = fileSize / 1024
            return "\(kb) KB"
        }
    }

    /// Formatted dimensions string (e.g., "480 × 270").
    var dimensionsText: String? {
        guard case .success(_, _, let dimensions) = exportState else { return nil }
        return "\(Int(dimensions.width)) × \(Int(dimensions.height))"
    }

    /// Combined info line: "3.2 MB · 480 × 270"
    var fileInfoText: String? {
        guard let size = fileSizeText, let dims = dimensionsText else { return nil }
        return "\(size) · \(dims)"
    }
}
