//
//  HomeViewModel.swift
//  ClipForge
//
//  Orchestrates the video import flow: clipboard detection → extraction
//  API call → video download → Trim Modal presentation.
//
//  STORY-011: HomeViewModel — Import Flow Orchestration
//

import Foundation
import Combine

/// Drives the Home screen's import flow.
///
/// Observes `ClipboardMonitor` for URL detection, then orchestrates
/// the two-phase import: extraction API call → video file retrieval.
/// The single `importState` property powers both the CTA button
/// appearance and the Trim Modal presentation trigger.
@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: - Published State

    /// Current state of the import pipeline. HomeView observes this
    /// to drive CTA button appearance and Trim Modal presentation.
    @Published var importState: ImportState = .idle

    /// Controls Trim Modal presentation via `.fullScreenCover`.
    @Published var showTrimModal = false

    // MARK: - Dependencies

    let clipboardMonitor: ClipboardMonitor
    private let apiService: APIService
    private var cancellables = Set<AnyCancellable>()
    private var importTask: Task<Void, Never>?

    // MARK: - Init

    init(
        clipboardMonitor: ClipboardMonitor = ClipboardMonitor(),
        apiService: APIService = .shared
    ) {
        self.clipboardMonitor = clipboardMonitor
        self.apiService = apiService

        observeClipboard()
    }

    // MARK: - Clipboard Observation

    /// Subscribes to ClipboardMonitor's published properties and
    /// updates `importState` when a URL is detected or cleared.
    private func observeClipboard() {
        // Observe supported URL detection
        clipboardMonitor.$detectedURL
            .combineLatest(clipboardMonitor.$detectedPlatform, clipboardMonitor.$isYouTubeURL)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] url, platform, isYouTube in
                guard let self else { return }

                // Don't override active import states
                switch self.importState {
                case .extracting, .downloading, .success:
                    #if DEBUG
                    print("HomeViewModel: ignoring clipboard update — import in progress (\(self.importState))")
                    #endif
                    return
                default:
                    break
                }

                if isYouTube {
                    #if DEBUG
                    print("HomeViewModel: YouTube URL detected — showing rejection message")
                    #endif
                    self.importState = .youtubeDetected
                } else if let url, let platform {
                    #if DEBUG
                    print("HomeViewModel: received URL from clipboard: \(url.absoluteString) (\(platform))")
                    #endif
                    self.importState = .urlDetected(url: url, platform: platform)
                } else {
                    #if DEBUG
                    print("HomeViewModel: no supported URL — state → idle")
                    #endif
                    self.importState = .idle
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Import Flow

    /// Starts the full import flow for the currently detected URL.
    ///
    /// Called when the user taps the CTA button while in `.urlDetected` state.
    /// Progresses through: extracting → downloading → success (or error).
    func startImport() {
        guard case .urlDetected(let url, let platform) = importState else {
            #if DEBUG
            print("HomeViewModel: CTA tapped but state is \(importState) — ignoring")
            #endif
            return
        }

        #if DEBUG
        print("HomeViewModel: CTA tapped, starting import for: \(url.absoluteString) (\(platform))")
        #endif
        importTask?.cancel()
        importTask = Task {
            await performImport(url: url)
        }
    }

    /// Resets from an error state so the user can retry.
    /// Re-checks the clipboard to restore URL detection.
    func retry() {
        importState = .idle
        clipboardMonitor.checkClipboard()
    }

    /// Resets after the Trim Modal is dismissed.
    func resetAfterExport() {
        importState = .idle
        showTrimModal = false
        clipboardMonitor.clearDetection()
    }

    // MARK: - Private

    /// Executes the two-phase import: extract → download.
    private func performImport(url: URL) async {
        // Phase 1: Extraction (indeterminate progress)
        #if DEBUG
        print("HomeViewModel: extraction started for \(url.absoluteString)")
        #endif
        importState = .extracting

        let extractionResponse: ExtractionResponse
        do {
            extractionResponse = try await apiService.extractVideo(url: url.absoluteString)
            #if DEBUG
            print("HomeViewModel: extraction succeeded — video_url = \(extractionResponse.videoURL.absoluteString)")
            #endif
        } catch let error as ClipForgeError {
            #if DEBUG
            print("HomeViewModel: extraction failed — \(error)")
            #endif
            importState = .error(message: error.errorDescription ?? "Something went wrong. Please try again.")
            return
        } catch {
            importState = .error(message: "Something went wrong. Please try again.")
            return
        }

        // Check for cancellation between phases
        guard !Task.isCancelled else { return }

        // Phase 2: Download (determinate progress)
        importState = .downloading(progress: 0.0)

        // Resolve video_url: backend may return a relative path (e.g. "/v1/media/...")
        // instead of the full URL the API Contract specifies. Handle both cases.
        let mediaURL: URL
        if extractionResponse.videoURL.scheme != nil {
            // Already absolute (has scheme like https://) — use as-is
            mediaURL = extractionResponse.videoURL
        } else {
            // Relative path — prepend the backend origin (scheme + host).
            // Configuration.baseURL includes /v1 so we use just the origin
            // to avoid doubling the path prefix.
            let origin = Configuration.baseURL.scheme! + "://" + Configuration.baseURL.host!
            guard let resolved = URL(string: origin + extractionResponse.videoURL.absoluteString) else {
                #if DEBUG
                print("HomeViewModel: could not resolve video_url — \(extractionResponse.videoURL)")
                #endif
                importState = .error(message: "Something went wrong. Please try again.")
                return
            }
            mediaURL = resolved
            #if DEBUG
            print("HomeViewModel: resolved relative video_url → \(mediaURL.absoluteString)")
            #endif
        }

        let localURL: URL
        do {
            localURL = try await apiService.downloadMedia(
                from: mediaURL
            ) { [weak self] progress in
                Task { @MainActor in
                    guard let self else { return }
                    // Only update if still in downloading state
                    if case .downloading = self.importState {
                        self.importState = .downloading(progress: progress)
                    }
                }
            }
        } catch let error as ClipForgeError {
            importState = .error(message: error.errorDescription ?? "Something went wrong. Please try again.")
            return
        } catch {
            importState = .error(message: "Something went wrong. Please try again.")
            return
        }

        guard !Task.isCancelled else { return }

        // Success — trigger Trim Modal
        #if DEBUG
        print("HomeViewModel: extraction complete, opening trim modal")
        #endif
        let metadata = extractionResponse.toVideoMetadata()
        importState = .success(localVideoURL: localURL, metadata: metadata)
        showTrimModal = true
    }

    // MARK: - Display Helpers

    /// User-facing message for the YouTube rejection state.
    /// Exact copy from STORY-011 AC-6.
    static let youTubeMessage = "YouTube isn't supported to keep ClipForge available on the App Store."

    /// The error message to display, if currently in error state.
    var errorMessage: String? {
        if case .error(let message) = importState {
            return message
        }
        if case .youtubeDetected = importState {
            return Self.youTubeMessage
        }
        return nil
    }

    /// Whether the CTA button should be tappable.
    var isButtonEnabled: Bool {
        switch importState {
        case .urlDetected:
            return true
        default:
            return false
        }
    }

    /// The download progress (0.0–1.0) if currently downloading, else nil.
    var downloadProgress: Double? {
        if case .downloading(let progress) = importState {
            return progress
        }
        return nil
    }
}
