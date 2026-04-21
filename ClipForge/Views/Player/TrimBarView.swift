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

/// Identifies which element a drag gesture is controlling.
private enum ActiveDragTarget {
    case startHandle
    case endHandle
}

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
    /// Which element the current drag is controlling.
    @State private var activeHandle: ActiveDragTarget? = nil

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

                    // Playhead (visual only — no gesture)
                    playheadVisual(filmstripWidth: filmstripWidth, videoDuration: videoDuration)

                }
                .frame(width: filmstripWidth, height: barHeight)
                .clipped()
                .overlay(alignment: .leading) {
                    handleVisual(
                        isLeading: true,
                        filmstripWidth: filmstripWidth,
                        videoDuration: videoDuration
                    )
                }
                .overlay(alignment: .leading) {
                    handleVisual(
                        isLeading: false,
                        filmstripWidth: filmstripWidth,
                        videoDuration: videoDuration
                    )
                }
                .contentShape(Rectangle())
                .highPriorityGesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { value in
                            // On first drag event, determine which handle based on proximity
                            if activeHandle == nil {
                                let startX = value.startLocation.x
                                let leftHandleX = timeToPosition(trimViewModel.startTime, filmstripWidth: filmstripWidth, videoDuration: videoDuration)
                                let rightHandleX = timeToPosition(trimViewModel.endTime, filmstripWidth: filmstripWidth, videoDuration: videoDuration)

                                let distToLeft = abs(startX - leftHandleX)
                                let distToRight = abs(startX - rightHandleX)

                                // 44pt proximity threshold (Apple HIG minimum touch target)
                                if distToLeft <= distToRight && distToLeft < 44 {
                                    activeHandle = .startHandle
                                    dragStartAnchor = trimViewModel.startTime
                                    #if DEBUG
                                    print("TrimBarView: activated LEFT handle drag")
                                    #endif
                                } else if distToRight < 44 {
                                    activeHandle = .endHandle
                                    dragEndAnchor = trimViewModel.endTime
                                    #if DEBUG
                                    print("TrimBarView: activated RIGHT handle drag")
                                    #endif
                                }
                            }

                            guard let handle = activeHandle else { return }

                            let timeDelta = (value.translation.width / filmstripWidth) * videoDuration

                            switch handle {
                            case .startHandle:
                                isDraggingStart = true
                                let anchor = dragStartAnchor ?? 0
                                let newTime = anchor + timeDelta
                                #if DEBUG
                                print("TrimBarView: START drag — anchor=\(anchor) delta=\(timeDelta) newTime=\(newTime) filmW=\(filmstripWidth) vidDur=\(videoDuration)")
                                #endif
                                trimViewModel.updateStartTime(newTime)

                                let now = Date()
                                if now.timeIntervalSince(lastSeekTime) > 0.1 {
                                    trimViewModel.seekToStart()
                                    lastSeekTime = now
                                }

                            case .endHandle:
                                isDraggingEnd = true
                                let anchor = dragEndAnchor ?? 0
                                let newTime = anchor + timeDelta
                                #if DEBUG
                                print("TrimBarView: END drag — anchor=\(anchor) delta=\(timeDelta) newTime=\(newTime) filmW=\(filmstripWidth) vidDur=\(videoDuration)")
                                #endif
                                trimViewModel.updateEndTime(newTime)

                                let now = Date()
                                if now.timeIntervalSince(lastSeekTime) > 0.1 {
                                    trimViewModel.seekToEnd()
                                    lastSeekTime = now
                                }
                            }
                        }
                        .onEnded { _ in
                            switch activeHandle {
                            case .startHandle:
                                trimViewModel.seekToStart()
                                isDraggingStart = false
                                dragStartAnchor = nil
                            case .endHandle:
                                trimViewModel.seekToEnd()
                                isDraggingEnd = false
                                dragEndAnchor = nil
                            case nil:
                                break
                            }
                            activeHandle = nil
                            lastSeekTime = .distantPast
                        }
                )
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

    // MARK: - Handle Visual (no gesture — container handles all touches)

    private func handleVisual(
        isLeading: Bool,
        filmstripWidth: CGFloat,
        videoDuration: Double
    ) -> some View {
        let time = isLeading ? trimViewModel.startTime : trimViewModel.endTime
        let xPosition = timeToPosition(time, filmstripWidth: filmstripWidth, videoDuration: videoDuration)
        let handleOffset = isLeading ? xPosition : xPosition - handleWidth
        let isDragging = isLeading ? isDraggingStart : isDraggingEnd

        return Rectangle()
            .fill(isDragging ? DesignTokens.vermillion : DesignTokens.vermillion.opacity(0.7))
            .frame(width: handleWidth, height: barHeight)
            .overlay(
                Image(systemName: isLeading ? "chevron.compact.left" : "chevron.compact.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            )
            .scaleEffect(isDragging ? 1.15 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isDragging)
            .offset(x: handleOffset)
            .allowsHitTesting(false)
    }

    // MARK: - Playhead Visual (no gesture — scrubbing deferred to v1.1)

    private func playheadVisual(filmstripWidth: CGFloat, videoDuration: Double) -> some View {
        let currentTime = playerManager.currentTime
        let xPosition = timeToPosition(currentTime, filmstripWidth: filmstripWidth, videoDuration: videoDuration)

        return VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white)
                .frame(width: 9, height: 6)

            Rectangle()
                .fill(Color.white)
                .frame(width: playheadWidth, height: barHeight - 6)
        }
        .offset(x: xPosition - playheadWidth / 2)
        .allowsHitTesting(false)
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
