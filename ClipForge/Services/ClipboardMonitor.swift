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
        #if DEBUG
        print("ClipboardMonitor: checking clipboard...")
        #endif
        let pasteboardString = UIPasteboard.general.string
        #if DEBUG
        print("ClipboardMonitor: clipboard content = \(pasteboardString ?? "<nil>")")
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
    }
}
