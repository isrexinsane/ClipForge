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

    /// Timer for a single delayed retry after the initial clipboard check.
    private var pollingTimer: Timer?

    /// Checks clipboard immediately, then schedules one delayed retry
    /// in case the iOS paste dialog was slow to resolve.
    func startPolling() {
        stopPolling()

        #if DEBUG
        print("ClipboardMonitor: checking clipboard on foreground")
        #endif

        // Check immediately
        checkClipboard()

        // If first check found something, we're done
        if detectedURL != nil || isYouTubeURL || isRedditURL {
            #if DEBUG
            print("ClipboardMonitor: URL found on first check")
            #endif
            return
        }

        // One delayed retry in case the paste dialog was slow to resolve.
        // Non-repeating — fires once then stops. Max 2 paste dialogs total.
        pollingTimer = Timer.scheduledTimer(
            withTimeInterval: 1.5,
            repeats: false
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                #if DEBUG
                print("ClipboardMonitor: delayed retry check")
                #endif
                self.checkClipboard()
            }
        }
    }

    /// Cancels any active polling timer.
    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
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

    /// Resets the duplicate-check tracker so the same clipboard
    /// content can be re-detected (e.g., after a failed import retry).
    func resetLastChecked() {
        lastCheckedString = nil
    }
}
