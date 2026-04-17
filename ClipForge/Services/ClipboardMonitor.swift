//
//  ClipboardMonitor.swift
//  ClipForge
//
//  Checks UIPasteboard for supported social media URLs when the
//  app enters the foreground. Publishes the detected URL, platform,
//  and YouTube rejection state for consumption by HomeViewModel.
//
//  STORY-010: ClipboardMonitor — URL Detection
//

import Foundation
import UIKit
import Combine

/// Monitors the system clipboard for supported social media URLs.
///
/// Call `checkClipboard()` whenever the app becomes active (on
/// `scenePhase` change to `.active`). The published properties
/// update synchronously on the main thread.
///
/// On iOS 16+, accessing `UIPasteboard.general.string` triggers
/// the system paste disclosure banner. This is expected behavior.
@MainActor
final class ClipboardMonitor: ObservableObject {

    /// A supported URL found on the clipboard, or `nil` if none detected.
    @Published private(set) var detectedURL: URL?

    /// Display name of the detected platform (e.g., "Twitter/X"), or `nil`.
    @Published private(set) var detectedPlatform: String?

    /// `true` when the clipboard contains a YouTube URL (detected and rejected).
    @Published private(set) var isYouTubeURL: Bool = false

    /// `true` when the clipboard contains a Reddit URL (removed from MVP).
    @Published private(set) var isRedditURL: Bool = false

    // Track the last checked string to avoid re-processing the same content.
    private var lastCheckedString: String?

    // MARK: - Polling

    /// Timer that fires every `pollingInterval` seconds after foregrounding.
    private var pollingTimer: Timer?
    /// When the current polling burst started.
    private var pollingStartTime: Date?
    /// How often to re-check the clipboard during a polling burst.
    private let pollingInterval: TimeInterval = 0.5
    /// Total duration of the polling burst (seconds).
    private let pollingDuration: TimeInterval = 3.0
    /// Running count for debug logging.
    private var pollCheckCount: Int = 0

    /// Begins an aggressive clipboard-polling burst.
    ///
    /// Checks immediately, then every 0.5 s for 3 seconds. Stops
    /// early if a URL is detected or `stopPolling()` is called.
    func startPolling() {
        stopPolling()
        pollingStartTime = Date()
        pollCheckCount = 0

        #if DEBUG
        print("ClipboardMonitor: starting polling")
        #endif

        // Check immediately
        pollCheckCount += 1
        #if DEBUG
        print("ClipboardMonitor: poll check \(pollCheckCount)/6")
        #endif
        checkClipboard()

        // If the first check already found something, don't schedule more
        if detectedURL != nil || isYouTubeURL || isRedditURL {
            #if DEBUG
            print("ClipboardMonitor: URL found on first check, stopping poll")
            #endif
            stopPolling()
            return
        }

        // Schedule repeated checks
        pollingTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }

                // Stop after duration expires
                if let start = self.pollingStartTime,
                   Date().timeIntervalSince(start) > self.pollingDuration {
                    #if DEBUG
                    print("ClipboardMonitor: polling timeout, stopping")
                    #endif
                    self.stopPolling()
                    return
                }

                // Stop if we already found a URL
                if self.detectedURL != nil || self.isYouTubeURL || self.isRedditURL {
                    #if DEBUG
                    print("ClipboardMonitor: URL found, stopping poll")
                    #endif
                    self.stopPolling()
                    return
                }

                self.pollCheckCount += 1
                #if DEBUG
                print("ClipboardMonitor: poll check \(self.pollCheckCount)/6")
                #endif
                self.checkClipboard()
            }
        }
    }

    /// Cancels any active polling burst.
    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        pollingStartTime = nil
    }

    /// Reads the system clipboard and updates published properties.
    ///
    /// Tries `UIPasteboard.general.url` first (some apps put links
    /// as URL objects), then falls back to `.string` and parses it.
    func checkClipboard() {
        #if DEBUG
        print("ClipboardMonitor: checking clipboard...")
        #endif

        // Try the URL pasteboard first — some apps put the link as a
        // URL object rather than a plain string.
        let pasteboardURL = UIPasteboard.general.url
        let pasteboardString = pasteboardURL?.absoluteString ?? UIPasteboard.general.string

        #if DEBUG
        print("ClipboardMonitor: clipboard url = \(pasteboardURL?.absoluteString ?? "<nil>"), string = \(UIPasteboard.general.string ?? "<nil>")")
        #endif

        // Skip if clipboard hasn't changed since last check
        guard pasteboardString != lastCheckedString else {
            #if DEBUG
            print("ClipboardMonitor: clipboard unchanged, skipping")
            #endif
            return
        }
        lastCheckedString = pasteboardString

        // Reset state
        detectedURL = nil
        detectedPlatform = nil
        isYouTubeURL = false
        isRedditURL = false

        guard let text = pasteboardString?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty,
              let url = URL(string: text),
              url.scheme == "http" || url.scheme == "https",
              url.host != nil else {
            #if DEBUG
            print("ClipboardMonitor: no valid URL found on clipboard")
            #endif
            return
        }

        #if DEBUG
        print("ClipboardMonitor: parsed URL with host = \(url.host ?? "<nil>"), path = \(url.path)")
        #endif

        // Check YouTube first — detected and rejected
        if SupportedPlatform.isYouTubeURL(url) {
            #if DEBUG
            print("ClipboardMonitor: YouTube URL detected and rejected")
            #endif
            isYouTubeURL = true
            return
        }

        // Check Reddit — removed from MVP, rejected with message
        if SupportedPlatform.isRedditURL(url) {
            #if DEBUG
            print("ClipboardMonitor: Reddit URL detected and rejected")
            #endif
            isRedditURL = true
            return
        }

        // Check supported platforms with host + path validation
        if let platform = SupportedPlatform.platform(forURL: url) {
            #if DEBUG
            print("ClipboardMonitor: found supported URL for \(platform.displayName): \(url.absoluteString)")
            #endif
            detectedURL = url
            detectedPlatform = platform.displayName
        } else {
            #if DEBUG
            print("ClipboardMonitor: URL host/path not in supported platforms list")
            #endif
        }
    }

    /// Clears all detected state. Call after the user dismisses a
    /// detection or after successfully starting an import.
    func clearDetection() {
        detectedURL = nil
        detectedPlatform = nil
        isYouTubeURL = false
        isRedditURL = false
    }
}
