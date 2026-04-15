//
//  TrimViewModel.swift
//  ClipForge
//
//  Core trim state management. Owns the trim range (start/end),
//  enforces duration constraints, drives player seeking, and
//  manages preview looping.
//
//  STORY-014: TrimViewModel — Core Trim State Management
//

import AVFoundation
import Combine

/// Color classification for the duration readout.
/// Drives text color in TrimModalView (STORY-017).
enum DurationColor: Equatable {
    /// ≤10 seconds — white text
    case normal
    /// >10 and ≤15 seconds — orange
    case warning
    /// >15 seconds — red, with "Long clips produce large files" note
    case danger
}

/// Manages the trim range state for the Trim Modal.
///
/// Holds references to `VideoPlayerManager` for player control.
/// All time values are in seconds (Double). Converts to CMTime
/// only when calling AVPlayer methods.
@MainActor
final class TrimViewModel: ObservableObject {

    // MARK: - Constraints

    /// Minimum trim duration in seconds.
    static let minDuration: Double = 0.5

    /// Maximum trim duration in seconds.
    static let maxDuration: Double = 30.0

    // MARK: - Published State

    /// Start of the trim selection in seconds.
    @Published private(set) var startTime: Double = 0.0

    /// End of the trim selection in seconds.
    @Published private(set) var endTime: Double = 0.0

    /// Computed trim duration (endTime - startTime).
    @Published private(set) var trimDuration: Double = 0.0

    /// Formatted duration string (e.g., "3.0s").
    @Published private(set) var durationText: String = "0.0s"

    /// Color classification for the duration readout.
    @Published private(set) var durationColor: DurationColor = .normal

    /// Whether the CREATE button should be enabled.
    @Published private(set) var isNextEnabled: Bool = false

    /// Whether preview loop is currently active.
    @Published private(set) var isPreviewLooping: Bool = false

    // MARK: - Dependencies

    let playerManager: VideoPlayerManager

    /// Total duration of the source video in seconds.
    private let videoDuration: Double

    /// Whether the user has moved at least one handle from default.
    private var hasUserAdjusted: Bool = false

    /// Boundary time observer token for preview loop.
    private var boundaryObserver: Any?

    // MARK: - Init

    /// Creates a TrimViewModel for a loaded video.
    ///
    /// - Parameters:
    ///   - playerManager: The active VideoPlayerManager from the Trim Modal.
    ///   - videoDuration: Total video duration in seconds.
    init(playerManager: VideoPlayerManager, videoDuration: Double) {
        self.playerManager = playerManager
        self.videoDuration = videoDuration

        // Initialize endTime to video duration (clamped to max trim)
        let clampedEnd = min(videoDuration, Self.maxDuration)
        self.endTime = clampedEnd
        self.startTime = 0.0

        updateComputedProperties()

        // If source video is ≤30s, CREATE is immediately available
        if videoDuration <= Self.maxDuration {
            isNextEnabled = true
        }
    }

    deinit {
        // Remove observer directly — can't call @MainActor methods from deinit.
        if let observer = boundaryObserver {
            playerManager.player.removeTimeObserver(observer)
        }
    }

    // MARK: - Handle Updates

    /// Updates the start time from a handle drag.
    ///
    /// Clamps to valid range: [0, endTime - minDuration].
    /// Also clamps so the range doesn't exceed maxDuration.
    func updateStartTime(_ time: Double) {
        let minStart = 0.0
        let maxStart = endTime - Self.minDuration

        var clamped = min(max(time, minStart), maxStart)

        // Enforce max duration: startTime >= endTime - maxDuration
        let minForMaxDuration = endTime - Self.maxDuration
        if clamped < minForMaxDuration {
            clamped = max(minForMaxDuration, 0.0)
        }

        startTime = clamped
        hasUserAdjusted = true
        updateComputedProperties()
    }

    /// Updates the end time from a handle drag.
    ///
    /// Clamps to valid range: [startTime + minDuration, videoDuration].
    /// Also clamps so the range doesn't exceed maxDuration.
    func updateEndTime(_ time: Double) {
        let minEnd = startTime + Self.minDuration
        let maxEnd = videoDuration

        var clamped = min(max(time, minEnd), maxEnd)

        // Enforce max duration: endTime <= startTime + maxDuration
        let maxForMaxDuration = startTime + Self.maxDuration
        if clamped > maxForMaxDuration {
            clamped = maxForMaxDuration
        }

        endTime = clamped
        hasUserAdjusted = true
        updateComputedProperties()
    }

    // MARK: - Seeking

    /// Seeks the player to the current start time. Frame-accurate.
    func seekToStart() {
        let cmTime = CMTime(seconds: startTime, preferredTimescale: 600)
        playerManager.player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    /// Seeks the player to the current end time. Frame-accurate.
    func seekToEnd() {
        let cmTime = CMTime(seconds: endTime, preferredTimescale: 600)
        playerManager.player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    // MARK: - Preview Loop

    /// Starts looping playback between startTime and endTime.
    ///
    /// Uses a boundary time observer to detect when playback reaches
    /// endTime, then seeks back to startTime for seamless looping.
    func startPreviewLoop() {
        guard !isPreviewLooping else { return }

        removeLoopObserver()

        // Seek to start of trim range
        let startCMTime = CMTime(seconds: startTime, preferredTimescale: 600)
        playerManager.player.seek(to: startCMTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.addLoopObserver()
                self.playerManager.play()
                self.isPreviewLooping = true
            }
        }
    }

    /// Stops the preview loop. Player pauses at current position.
    func stopPreviewLoop() {
        removeLoopObserver()
        playerManager.pause()
        isPreviewLooping = false
    }

    /// Toggles preview loop on/off.
    func togglePreviewLoop() {
        if isPreviewLooping {
            stopPreviewLoop()
        } else {
            startPreviewLoop()
        }
    }

    // MARK: - Private

    /// Recalculates all derived properties from startTime and endTime.
    private func updateComputedProperties() {
        trimDuration = endTime - startTime
        durationText = String(format: "%.1fs", trimDuration)

        if trimDuration > 15.0 {
            durationColor = .danger
        } else if trimDuration > 10.0 {
            durationColor = .warning
        } else {
            durationColor = .normal
        }

        // isNextEnabled: true if user adjusted OR source ≤30s
        isNextEnabled = hasUserAdjusted || videoDuration <= Self.maxDuration
    }

    /// Adds a boundary time observer that fires when playback reaches endTime.
    private func addLoopObserver() {
        let endCMTime = CMTime(seconds: endTime, preferredTimescale: 600)
        boundaryObserver = playerManager.player.addBoundaryTimeObserver(
            forTimes: [NSValue(time: endCMTime)],
            queue: .main
        ) { [weak self] in
            Task { @MainActor in
                guard let self, self.isPreviewLooping else { return }
                let startCMTime = CMTime(seconds: self.startTime, preferredTimescale: 600)
                self.playerManager.player.seek(
                    to: startCMTime,
                    toleranceBefore: .zero,
                    toleranceAfter: .zero
                )
            }
        }
    }

    /// Removes the boundary time observer if present.
    private func removeLoopObserver() {
        if let observer = boundaryObserver {
            playerManager.player.removeTimeObserver(observer)
            boundaryObserver = nil
        }
    }
}
