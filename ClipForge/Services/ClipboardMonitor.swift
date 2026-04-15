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

    // Track the last checked string to avoid re-processing the same content.
    private var lastCheckedString: String?

    /// Reads the system clipboard and updates published properties.
    ///
    /// Should be called from the app's scene phase observer when
    /// transitioning to `.active`.
    func checkClipboard() {
        print("ClipboardMonitor: checking clipboard...")
        let pasteboardString = UIPasteboard.general.string
        print("ClipboardMonitor: clipboard content = \(pasteboardString ?? "<nil>")")

        // Skip if clipboard hasn't changed since last check
        guard pasteboardString != lastCheckedString else {
            print("ClipboardMonitor: clipboard unchanged, skipping")
            return
        }
        lastCheckedString = pasteboardString

        // Reset state
        detectedURL = nil
        detectedPlatform = nil
        isYouTubeURL = false

        guard let text = pasteboardString?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty,
              let url = URL(string: text),
              url.scheme == "http" || url.scheme == "https",
              url.host != nil else {
            print("ClipboardMonitor: no valid URL found on clipboard")
            return
        }

        print("ClipboardMonitor: parsed URL with host = \(url.host ?? "<nil>"), path = \(url.path)")

        // Check YouTube first — detected and rejected
        if SupportedPlatform.isYouTubeURL(url) {
            print("ClipboardMonitor: YouTube URL detected and rejected")
            isYouTubeURL = true
            return
        }

        // Check supported platforms with host + path validation
        if let platform = SupportedPlatform.platform(forURL: url) {
            print("ClipboardMonitor: found supported URL for \(platform.displayName): \(url.absoluteString)")
            detectedURL = url
            detectedPlatform = platform.displayName
        } else {
            print("ClipboardMonitor: URL host/path not in supported platforms list")
        }
    }

    /// Clears all detected state. Call after the user dismisses a
    /// detection or after successfully starting an import.
    func clearDetection() {
        detectedURL = nil
        detectedPlatform = nil
        isYouTubeURL = false
    }
}
