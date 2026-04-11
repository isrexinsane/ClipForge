//
//  GIFConfiguration.swift
//  ClipForge
//
//  User-selected parameters for GIF creation: the trim range,
//  quality preset, and any overrides.
//

import Foundation

/// Configuration for a single GIF encoding operation.
///
/// Combines the user's trim selection (start/end times) with the
/// chosen quality preset. The encoding pipeline reads these values
/// to extract frames, resize, and assemble the GIF.
struct GIFConfiguration: Sendable {

    /// Start of the trim range in seconds from the beginning of the video.
    var startTime: TimeInterval

    /// End of the trim range in seconds from the beginning of the video.
    var endTime: TimeInterval

    /// The quality preset controlling dimensions, frame rate, and size target.
    var preset: QualityPreset

    /// Maximum file size in megabytes. Defaults to the preset's target,
    /// but can be overridden if needed.
    var maxFileSizeMB: Double

    /// Frames per second. Defaults to the preset's frame rate,
    /// but may be reduced automatically during size optimization.
    var frameRate: Int

    /// Duration of the trimmed clip in seconds.
    var duration: TimeInterval {
        endTime - startTime
    }

    /// Creates a configuration with the given trim range and preset.
    /// File size and frame rate default to the preset's values.
    init(
        startTime: TimeInterval,
        endTime: TimeInterval,
        preset: QualityPreset,
        maxFileSizeMB: Double? = nil,
        frameRate: Int? = nil
    ) {
        self.startTime = startTime
        self.endTime = endTime
        self.preset = preset
        self.maxFileSizeMB = maxFileSizeMB ?? preset.targetFileSizeMB
        self.frameRate = frameRate ?? preset.frameRate
    }
}
