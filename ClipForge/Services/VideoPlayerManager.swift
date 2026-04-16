//
//  VideoPlayerManager.swift
//  ClipForge
//
//  Manages AVPlayer lifecycle for the Trim Modal. Creates a player
//  from a local video file, publishes playback state, and handles
//  mute toggle.
//
//  STORY-013: VideoPlayerManager + Trim Modal Shell
//

import AVFoundation
import Combine

/// Wraps AVPlayer for use in the Trim Modal.
///
/// On initialization, loads the video, seeks to the first frame
/// (preventing a black flash), then autoplays muted. Publishes
/// `currentTime` and `duration` for the trim bar (Epic 4).
@MainActor
final class VideoPlayerManager: ObservableObject {

    /// The AVPlayer instance for SwiftUI consumption.
    let player: AVPlayer

    /// Whether audio is muted. Defaults to `true`.
    @Published var isMuted: Bool = true {
        didSet { player.isMuted = isMuted }
    }

    /// Total video duration in seconds.
    @Published private(set) var duration: Double = 0

    /// Current playback position in seconds.
    @Published private(set) var currentTime: Double = 0

    /// Whether the player is currently playing.
    @Published private(set) var isPlaying: Bool = false

    private let asset: AVURLAsset
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var endObserver: NSObjectProtocol?

    /// Creates a player manager for a local video file.
    ///
    /// - Parameter videoURL: Local file URL (typically in Caches directory).
    init(videoURL: URL) {
        #if DEBUG
        print("VideoPlayerManager: loading \(videoURL.lastPathComponent)")
        #endif
        self.asset = AVURLAsset(url: videoURL)
        let item = AVPlayerItem(asset: asset)
        self.player = AVPlayer(playerItem: item)
        player.isMuted = true

        setupObservers()
        observeItemStatus(item)
        seekToFirstFrame()
    }

    deinit {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        statusObserver?.invalidate()
    }

    // MARK: - Playback Controls

    /// Starts or resumes playback.
    func play() {
        player.play()
        isPlaying = true
    }

    /// Pauses playback.
    func pause() {
        player.pause()
        isPlaying = false
    }

    /// Toggles between play and pause.
    func togglePlayback() {
        if isPlaying { pause() } else { play() }
    }

    /// Toggles between muted and unmuted.
    func toggleMute() {
        isMuted.toggle()
    }

    // MARK: - Setup

    /// Seeks to the very first frame so the player displays a frame
    /// immediately, avoiding a black flash before autoplay starts.
    private func seekToFirstFrame() {
        player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            Task { @MainActor in
                self?.loadDurationAndAutoplay()
            }
        }
    }

    /// Loads the asset duration, then starts autoplay.
    private func loadDurationAndAutoplay() {
        Task {
            do {
                let cmDuration = try await asset.load(.duration)
                duration = CMTimeGetSeconds(cmDuration)
            } catch {
                duration = 0
            }
            play()
        }
    }

    /// Watches the player item status so format errors surface in the console.
    private func observeItemStatus(_ item: AVPlayerItem) {
        statusObserver = item.observe(\.status, options: [.new]) { item, _ in
            #if DEBUG
            switch item.status {
            case .readyToPlay:
                print("VideoPlayerManager: item ready to play")
            case .failed:
                print("VideoPlayerManager: item FAILED — \(item.error?.localizedDescription ?? "unknown error")")
                if let err = item.error as NSError? {
                    print("VideoPlayerManager: domain=\(err.domain) code=\(err.code)")
                }
            default:
                break
            }
            #endif
        }
    }

    /// Sets up time observation and end-of-video looping.
    private func setupObservers() {
        // Periodic time observer — updates currentTime ~15 times/second
        let interval = CMTime(seconds: 1.0 / 15.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                self?.currentTime = CMTimeGetSeconds(time)
            }
        }

        // Loop video when it reaches the end
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
                self?.play()
            }
        }
    }
}
