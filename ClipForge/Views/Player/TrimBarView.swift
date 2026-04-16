//
//  TrimBarView.swift
//  ClipForge
//
//  Visual timeline scrubber with filmstrip thumbnails, draggable
//  trim handles, playhead, and play button. iOS Photos editor pattern.
//
//  STORY-016: TrimBarView — Timeline Scrubber UI
//

import SwiftUI

/// The trim bar displayed at the bottom of the Trim Modal.
///
/// Layout: [Play button | Filmstrip with handles + playhead]
/// Handles map horizontal position to video time via TrimViewModel.
struct TrimBarView: View {

    @ObservedObject var trimViewModel: TrimViewModel
    @ObservedObject var playerManager: VideoPlayerManager
    @ObservedObject var filmstripGenerator: FilmstripGenerator

    /// Whether each handle is currently being dragged (for visual feedback).
    @State private var isDraggingStart = false
    @State private var isDraggingEnd = false

    /// Captured handle time at drag start — translation is applied relative to this.
    @State private var dragStartAnchor: Double?
    @State private var dragEndAnchor: Double?

    /// Throttle: last time a seek was issued during drag.
    @State private var lastSeekTime: Date = .distantPast

    private let barHeight: CGFloat = 56
    private let playButtonWidth: CGFloat = 50
    private let handleWidth: CGFloat = 16
    private let playheadWidth: CGFloat = 3
    private let borderWidth: CGFloat = 2.5
    /// Minimum invisible hit area per Apple HIG (44×44pt).
    private let minHitArea: CGFloat = 44

    var body: some View {
        GeometryReader { geometry in
            let filmstripWidth = geometry.size.width - playButtonWidth - 1 // 1px divider
            let videoDuration = playerManager.duration

            HStack(spacing: 0) {
                // Play button
                playButton
                    .frame(width: playButtonWidth, height: barHeight)

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 1, height: barHeight)

                // Filmstrip + handles + playhead
                ZStack(alignment: .leading) {
                    // Filmstrip thumbnails
                    filmstrip
                        .frame(height: barHeight)

                    // Dimming overlays outside selection
                    dimmingOverlays(filmstripWidth: filmstripWidth, videoDuration: videoDuration)

                    // Selection border (top and bottom lines between handles)
                    selectionBorder(filmstripWidth: filmstripWidth, videoDuration: videoDuration)

                    // Left handle
                    trimHandle(
                        isLeading: true,
                        filmstripWidth: filmstripWidth,
                        videoDuration: videoDuration
                    )

                    // Right handle
                    trimHandle(
                        isLeading: false,
                        filmstripWidth: filmstripWidth,
                        videoDuration: videoDuration
                    )

                    // Playhead
                    playhead(filmstripWidth: filmstripWidth, videoDuration: videoDuration)
                }
                .frame(width: filmstripWidth, height: barHeight)
                .clipped()
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: 0x3A3A3C))
            )
        }
        .frame(height: barHeight)
    }

    // MARK: - Play Button

    private var playButton: some View {
        Button {
            trimViewModel.togglePreviewLoop()
        } label: {
            Image(systemName: trimViewModel.isPreviewLooping ? "pause.fill" : "play.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Filmstrip

    private var filmstrip: some View {
        HStack(spacing: 0) {
            ForEach(Array(filmstripGenerator.thumbnails.enumerated()), id: \.offset) { _, image in
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: barHeight)
                    .clipped()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Dimming Overlays

    private func dimmingOverlays(filmstripWidth: CGFloat, videoDuration: Double) -> some View {
        ZStack(alignment: .leading) {
            // Left dim: 0 → startTime
            let leftWidth = timeToPosition(trimViewModel.startTime, filmstripWidth: filmstripWidth, videoDuration: videoDuration)
            Rectangle()
                .fill(Color.black.opacity(0.6))
                .frame(width: max(leftWidth, 0), height: barHeight)

            // Right dim: endTime → end
            let rightX = timeToPosition(trimViewModel.endTime, filmstripWidth: filmstripWidth, videoDuration: videoDuration)
            let rightWidth = filmstripWidth - rightX
            Rectangle()
                .fill(Color.black.opacity(0.6))
                .frame(width: max(rightWidth, 0), height: barHeight)
                .offset(x: rightX)
        }
    }

    // MARK: - Selection Border

    private func selectionBorder(filmstripWidth: CGFloat, videoDuration: Double) -> some View {
        let leftX = timeToPosition(trimViewModel.startTime, filmstripWidth: filmstripWidth, videoDuration: videoDuration) + handleWidth
        let rightX = timeToPosition(trimViewModel.endTime, filmstripWidth: filmstripWidth, videoDuration: videoDuration) - handleWidth
        let selectionWidth = rightX - leftX

        return ZStack(alignment: .leading) {
            // Top border
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: max(selectionWidth, 0), height: borderWidth)
                .offset(x: leftX)

            // Bottom border
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: max(selectionWidth, 0), height: borderWidth)
                .offset(x: leftX, y: barHeight - borderWidth)
        }
        .frame(height: barHeight, alignment: .top)
    }

    // MARK: - Trim Handle

    private func trimHandle(
        isLeading: Bool,
        filmstripWidth: CGFloat,
        videoDuration: Double
    ) -> some View {
        let time = isLeading ? trimViewModel.startTime : trimViewModel.endTime
        let xPosition = timeToPosition(time, filmstripWidth: filmstripWidth, videoDuration: videoDuration)
        let handleOffset = isLeading ? xPosition : xPosition - handleWidth
        let isDragging = isLeading ? isDraggingStart : isDraggingEnd

        return Rectangle()
            .fill(isDragging ? DesignTokens.vermillion.opacity(0.85) : Color.white.opacity(0.3))
            .frame(width: handleWidth, height: barHeight)
            .overlay(
                Image(systemName: isLeading ? "chevron.compact.left" : "chevron.compact.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            )
            .scaleEffect(isDragging ? 1.15 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isDragging)
            // 44pt-wide invisible hit area centered on the visible handle
            .padding(.horizontal, (minHitArea - handleWidth) / 2)
            .contentShape(Rectangle())
            .offset(x: handleOffset - (minHitArea - handleWidth) / 2)
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        // Update dragging flag
                        if isLeading { isDraggingStart = true } else { isDraggingEnd = true }

                        // Capture the handle's time at drag start (first onChanged call)
                        if isLeading {
                            if dragStartAnchor == nil { dragStartAnchor = trimViewModel.startTime }
                        } else {
                            if dragEndAnchor == nil { dragEndAnchor = trimViewModel.endTime }
                        }

                        // Convert pixel translation to time delta, then apply to anchor
                        let anchor = isLeading ? (dragStartAnchor ?? 0) : (dragEndAnchor ?? 0)
                        let timeDelta = (value.translation.width / filmstripWidth) * videoDuration
                        let newTime = anchor + timeDelta

                        if isLeading {
                            trimViewModel.updateStartTime(newTime)
                        } else {
                            trimViewModel.updateEndTime(newTime)
                        }

                        // Throttle seeks to every 0.1s to avoid overwhelming AVPlayer
                        let now = Date()
                        if now.timeIntervalSince(lastSeekTime) > 0.1 {
                            if isLeading {
                                trimViewModel.seekToStart()
                            } else {
                                trimViewModel.seekToEnd()
                            }
                            lastSeekTime = now
                        }
                    }
                    .onEnded { _ in
                        // Final seek to the committed position
                        if isLeading {
                            trimViewModel.seekToStart()
                            isDraggingStart = false
                            dragStartAnchor = nil
                        } else {
                            trimViewModel.seekToEnd()
                            isDraggingEnd = false
                            dragEndAnchor = nil
                        }

                        lastSeekTime = .distantPast
                    }
            )
    }

    // MARK: - Playhead

    private func playhead(filmstripWidth: CGFloat, videoDuration: Double) -> some View {
        let currentTime = playerManager.currentTime
        let xPosition = timeToPosition(currentTime, filmstripWidth: filmstripWidth, videoDuration: videoDuration)

        return VStack(spacing: 0) {
            // Rounded nub at top
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white)
                .frame(width: 9, height: 6)

            // Vertical line
            Rectangle()
                .fill(Color.white)
                .frame(width: playheadWidth, height: barHeight - 6)
        }
        .offset(x: xPosition - playheadWidth / 2)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    // Use startLocation for initial tap, then translation for movement
                    let startX = timeToPosition(playerManager.currentTime, filmstripWidth: filmstripWidth, videoDuration: videoDuration)
                    let dragX = startX + value.translation.width
                    let time = positionToTime(dragX, filmstripWidth: filmstripWidth, videoDuration: videoDuration)
                    let clampedTime = min(max(time, 0), videoDuration)
                    let cmTime = CMTime(seconds: clampedTime, preferredTimescale: 600)
                    playerManager.player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
                }
        )
    }

    // MARK: - Coordinate Mapping

    /// Converts a video time (seconds) to an x-position within the filmstrip.
    private func timeToPosition(_ time: Double, filmstripWidth: CGFloat, videoDuration: Double) -> CGFloat {
        guard videoDuration > 0 else { return 0 }
        return CGFloat(time / videoDuration) * filmstripWidth
    }

    /// Converts an x-position within the filmstrip to a video time (seconds).
    private func positionToTime(_ position: CGFloat, filmstripWidth: CGFloat, videoDuration: Double) -> Double {
        guard filmstripWidth > 0 else { return 0 }
        return Double(position / filmstripWidth) * videoDuration
    }
}

// AVFoundation import for CMTime in playhead scrubbing
import AVFoundation
