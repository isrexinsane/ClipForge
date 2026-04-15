---
title: "ClipForge — Product Requirements Document (PRD)"
agent: PM
phase: Planning
status: Complete
date: 2026-04-10
project: ClipForge
org: Ronin Art House
depends_on: Project_Brief.md
---

# ClipForge — Product Requirements Document

## 1. Product Vision

ClipForge is the fastest way to turn a social media moment into a shareable reaction GIF on iOS. It replaces a fragmented, multi-app workflow with a single five-step experience: paste a link, preview the video, trim to the moment, configure the GIF, and export to the camera roll. The entire process takes under 30 seconds.

ClipForge is a GIF creation tool powered by social media content. It is not a video downloader. The video import exists to serve the creative workflow, and every product decision — from the App Store listing language to the UI hierarchy — reflects this positioning.

## 2. User Personas

These personas are carried forward from the Project Brief and expanded with usage scenarios specific to the PRD.

### 2.1 Dante — The Reaction GIF Creator

Age 24. Heavy Twitter/X and Discord user. Creates reaction GIFs several times per week to share in group chats. Values speed above all — the faster he can capture a moment, the more social capital he earns.

**Primary usage scenario:** Dante is watching an NBA game while active in a Discord voice channel. A coach makes an incredulous face and someone tweets the clip. Dante copies the tweet URL, opens ClipForge, pastes the link, scrubs to the three-second reaction shot, taps export, and drops the GIF into Discord. Elapsed time: under 30 seconds. The moment is still live in the conversation.

**Secondary usage scenario:** Dante is scrolling Twitter/X and spots a clip he knows will be useful as a reaction later. He runs it through ClipForge, trims the best moment, and saves the GIF to his camera roll for future use. He is building a personal reaction GIF library.

**Tier behavior:** Free tier initially; converts to premium within the first session once he hits the one-per-day limit.

### 2.2 Priya — The Community Moderator

Age 29. UX designer. Moderates a 5,000-member anime Discord server. Curates custom reaction GIFs and emoji from anime clips, fan edits, and TikTok compilations. Needs precise control over output file size to meet Discord's limits.

**Primary usage scenario:** Priya sees a trending anime clip on Twitter/X while commuting. She opens ClipForge, imports the clip, trims a specific two-second expression, and exports the auto-optimized GIF (≤8 MB, clears all platform limits). She uploads it as a custom emoji to her server from her phone, maintaining her desktop-quality curation workflow on mobile.

**Secondary usage scenario:** Priya is building a themed GIF set for a server event. She processes five clips from different platforms in a single sitting, using the premium tier for watermark-free output for the server's Nitro-boosted channels.

**Tier behavior:** Subscribes to premium immediately for unlimited exports, HD quality, and watermark-free output.

### 2.3 Tyler — The Casual Memer

Age 19. College freshman. Uses iMessage group chats and Instagram constantly. Shares funny moments with friends but does not think of himself as a content creator. Has zero technical knowledge and zero patience for complex tools.

**Primary usage scenario:** Tyler sees a funny moment on Instagram Reels. He copies the link, opens ClipForge, and the app immediately starts loading the video. He drags the trim handles to the funny part, taps the big green export button, and the GIF appears in his camera roll. He sends it in iMessage. He never touches a settings menu.

**Secondary usage scenario:** A friend sends Tyler a Reddit link in their group chat with "this would be a great GIF." Tyler opens ClipForge, pastes the link, trims it, and sends back the GIF within a minute.

**Tier behavior:** Free tier indefinitely. One GIF per day covers most casual sessions. Represents organic growth — he tells friends about the app when they ask how he made the GIF.

## 3. Feature Inventory

### 3.1 MVP Features (v1.0 Launch)

| ID | Feature | Description |
|----|---------|-------------|
| F-01 | Link paste and video import | User pastes a social media URL; app sends it to the backend API; backend extracts the video; app receives and displays it in a player |
| F-02 | Clipboard detection | On app launch or foreground return, detect a supported URL on the clipboard and prompt the user to import it |
| F-03 | Video preview player | Full video playback with standard controls (play/pause, scrub) so the user can find the moment they want |
| F-04 | Trim interface | Timeline scrubber with draggable start and end handles. Visual frame markers. Real-time preview of the trimmed segment with looping playback |
| F-05 | GIF encoding engine | Convert the trimmed video segment into an animated GIF using native iOS frameworks (ImageIO / CoreGraphics) |
| F-07 | Camera roll export | Save the generated GIF to the iOS Photos library, immediately available for sharing via the share sheet |
| F-08 | Freemium gating | Free tier: 1 GIF export per day. Premium tier: unlimited exports, no watermark |
| F-09 | Watermark (free tier) | Small, semi-transparent ClipForge logomark (PNG asset, swappable when final branding is complete) in the bottom-right corner of GIFs created on the free tier |
| F-10 | Error handling and status feedback | Clear, non-technical messaging for every failure state: unsupported URL, platform temporarily unavailable, network error, encoding failure |
| F-11 | Onboarding flow | Three-screen tutorial on first launch showing the paste → trim → export workflow. Skippable. |
| F-12 | Privacy and legal compliance | Zero personal data collection. Privacy policy accessible from settings. In-app copyright disclaimer. No account creation required. |

### 3.2 Post-Launch Features (v1.x and Beyond)

| ID | Feature | Description | Priority |
|----|---------|-------------|----------|
| F-20 | MP4 clip export (premium) | Export the trimmed segment as an MP4 video file in addition to GIF | High — v1.1 |
| F-21 | Share sheet integration | Accept URLs directly via the iOS share sheet ("Share to ClipForge") so users can import without manually copying and pasting | High — v1.1 |
| F-22 | GIF history / library | In-app gallery of previously created GIFs for re-sharing. **MVP note:** Media Library provides a visual grid of previously created GIFs. Tapping a tile opens the iOS share sheet directly. In-app GIF management (delete, rename, organize) is deferred to v1.2+. | Medium — v1.2 |
| F-23 | Text overlay | Add caption text to GIFs before export | Medium — v1.2 |
| F-24 | Speed adjustment | Slow motion and speed-up controls for the trimmed segment | Medium — v1.2 |
| F-25 | Crop and resize | Adjust the frame dimensions before GIF encoding | Low — v1.3 |
| F-26 | Custom frame rate | User-adjustable FPS for fine-tuning file size vs. smoothness | Low — v1.3 |
| F-27 | iMessage app integration | Browse and send previously created GIFs directly from the iMessage app drawer | Low — v2.0 |
| F-28 | Widget / shortcut | iOS home screen widget or Shortcuts integration for one-tap import from clipboard | Low — v2.0 |

### 3.3 Explicit Scope Exclusions (Not in MVP)

These are deliberately excluded from v1.0 to maintain focus and reduce App Store risk:

- YouTube support (hard constraint — highest App Store rejection risk)
- User accounts or login (zero data collection policy)
- Social sharing directly to platforms from within the app (camera roll is the output; the user shares from there)
- Cloud storage or sync of GIF history
- Video filters, color adjustment, or effects beyond trimming
- Batch processing (multiple URLs at once)
- User-configurable quality presets (deferred; single auto-optimized encoding replaces presets)
- Android version

## 4. User Flows

### 4.1 Flow 1 — Paste Link and Import Video

**Trigger:** User has copied a supported social media URL to the clipboard.

1. User opens ClipForge.
2. App checks the clipboard for a URL matching a supported platform pattern (Twitter/X, Instagram, Reddit, TikTok, Twitch).
3. If a supported URL is detected, the app displays a prompt: "Create a GIF from this [Platform] link?" with a preview of the URL and "Import" / "Dismiss" buttons.
4. If no URL is detected, the app shows the home screen with a manual paste field and brief instructions ("Copy a link from Twitter, Instagram, Reddit, or TikTok, then come back here").
5. User taps "Import" (or manually pastes a URL and taps the import button).
6. The CREATE GIF button's circular border becomes a progress ring. During the backend extraction API call (typically 2–8 seconds), the ring shows an indeterminate animation (slow pulse or rotation). Once the signed URL is received, the vermillion (#EF3340) stroke animates clockwise proportional to the video file download progress via URLSession. On completion, the app transitions to the Trim Modal with the video loaded.
7. App sends the URL to the ClipForge backend API over HTTPS.
8. Backend validates the URL, runs yt-dlp to extract the video, and returns the direct video data or a temporary signed URL to the video file.
9. App receives the video and transitions to the video preview player (Flow 2 entry point).

**Error states:**
- Unsupported URL format → "This link isn't supported yet. ClipForge works with Twitter/X, Instagram, Reddit, TikTok, and Twitch."
- Backend extraction failure → "We couldn't get the video from this link. The platform may have changed something — try again in a bit."
- Network unavailable → "No internet connection. Connect to Wi-Fi or cellular to import videos."
- Backend timeout (>15 seconds) → "This is taking longer than expected. Tap to retry."

### 4.2 Flow 2 — Trim Video

**Trigger:** Video has been successfully imported and loaded into the player.

**Design note (v2):** The trim interface follows the iOS Photos/Camera video editor pattern: black background, edge-to-edge video, iOS Photos-style trim bar with play button, chevron handles, and playhead. The GIF Settings screen has been removed — the user proceeds directly from trim to encoding.

1. App displays the video in a player view with standard playback controls (play/pause, current time indicator).
2. Below the player, a horizontal timeline scrubber shows the full video duration with thumbnail frames.
3. Two draggable trim handles (start and end) appear on the timeline, initially set to the full video length.
4. User drags the start handle to set the beginning of the clip. The player jumps to the selected frame in real time as the handle moves.
5. User drags the end handle to set the end of the clip. Same real-time preview behavior.
6. A duration indicator displays the length of the selected segment (e.g., "2.4s"). The indicator changes color if the segment exceeds the recommended maximum for GIF (10 seconds) — orange for 10–15s, red for >15s with a note: "Long clips produce large files."
7. User taps "Preview Loop" to watch the trimmed segment play in a continuous loop, confirming the selection.
8. User taps "Next" to begin GIF encoding (Flow 4 entry point).

**Constraints:**
- Minimum trim duration: 0.5 seconds.
- Maximum trim duration: 30 seconds (hard limit; the encoding engine will refuse longer segments).
- Trim handle precision: frame-accurate, snapping to the nearest keyframe for clean start/end points.

### 4.3 Flow 3 — Configure GIF Settings

**REMOVED in v2.** Flow 3 (GIF Settings) has been eliminated. No settings screen exists. User proceeds directly from Flow 2 (Trim) to Flow 4 (Export) with automatic, no-configuration encoding. Single "Works Everywhere" target (≤8 MB, auto-optimized resolution and frame rate) replaces the preset selector.

### 4.4 Flow 4 — Export GIF to Camera Roll

**Trigger:** User has confirmed a trimmed segment and tapped "CREATE" within the Trim Modal.

1. The CREATE button within the Trim Modal transforms into a circular progress ring with a percentage indicator (JetBrains Mono Bold, white, centered). The trim bar and duration readout remain visible above. Text below the ring: "Creating your GIF..." in JetBrains Mono Medium, secondary text color (#968C83). Cancel button in the top bar remains available to abort encoding.
2. The GIF encoding engine processes the trimmed segment: extracts frames at the auto-selected frame rate (10–15 FPS based on trim duration), applies palette optimization, encodes as animated GIF via ImageIO, applies lossy compression if needed to stay within the ≤8 MB "Works Everywhere" target file size.
3. If the user is on the free tier, the watermark is composited onto each frame during encoding.
4. Encoding completes. App requests Photos library write permission if not previously granted (standard iOS permission prompt). GIF is saved to the camera roll via PHPhotoLibrary.
5. The Trim Modal transitions to the export success state (same modal, no navigation): the video area now shows the finished GIF playing in a loop. The trim bar disappears.
6. Below the GIF preview: file size and dimensions readout (e.g., "3.2 MB · 480 × 270") in JetBrains Mono Medium, white.
7. Two pill-shaped action buttons side by side: "Share" (vermillion fill #EF3340, opens the iOS share sheet with the GIF pre-loaded) and "Done" (white outline/ghost style, dismisses modal and returns to Home screen).
8. On the free tier, small text above the buttons: "0 of 1 free GIFs remaining today" in secondary text color (#968C83).

**Error states:**
- Photos permission denied → "ClipForge needs access to your photo library to save GIFs. You can enable this in Settings > Privacy > Photos."
- Encoding failure → "Something went wrong creating the GIF. Try a shorter clip or a smaller size preset."
- File size exceeds target despite compression → App attempts a second pass at lower quality. If still over, shows the GIF with a note: "This GIF is [X] MB — larger than the [preset] target. It may exceed some platform limits."

## 5. Acceptance Criteria

### 5.1 F-01: Link Paste and Video Import

- AC-01.1: The app accepts URLs from Twitter/X, Instagram, Reddit, TikTok, and Twitch. Each platform has at least three URL format variations tested (e.g., twitter.com, x.com, mobile.twitter.com for Twitter/X).
- AC-01.2: A valid URL submitted to the backend returns playable video data within 15 seconds on a typical LTE connection.
- AC-01.3: The imported video loads into the preview player without re-encoding or format conversion on the device.
- AC-01.4: If the backend returns an error, the app displays a human-readable message (not a status code or stack trace) and offers a "Retry" action.
- AC-01.5: No user-facing string in the app contains the word "download." All import-related UI uses "import," "capture," or "create from link."

### 5.2 F-02: Clipboard Detection

- AC-02.1: On app launch or return to foreground, the app checks the clipboard for a URL matching a supported platform pattern.
- AC-02.2: If a supported URL is found, a non-blocking prompt appears within 1 second: "Create a GIF from this [Platform] link?"
- AC-02.3: The prompt can be dismissed without action. Dismissing does not consume or clear the clipboard.
- AC-02.4: The app respects iOS clipboard access disclosure. On iOS 16+, the system paste confirmation dialog is handled correctly (the app does not attempt to read the clipboard silently).
- AC-02.5: If the clipboard contains an unsupported URL or non-URL content, no prompt is shown.

### 5.3 F-03: Video Preview Player

- AC-03.1: Imported video plays in a native player view with play/pause toggle and a time indicator showing current position and total duration.
- AC-03.2: The user can scrub to any point in the video using the timeline.
- AC-03.3: Audio is muted by default (GIFs have no audio; the preview should reflect the output).
- AC-03.4: The player scales video to fit the screen width while maintaining the original aspect ratio. No cropping or stretching.
- AC-03.5: The player renders the first frame immediately upon load, before the user taps play.

### 5.4 F-04: Trim Interface

- AC-04.1: Start and end trim handles are rendered on the timeline scrubber and are draggable by touch.
- AC-04.2: Dragging a handle updates the player position in real time (frame-accurate scrubbing).
- AC-04.3: The duration indicator updates in real time as handles are moved and accurately reflects the selected segment length to one decimal place.
- AC-04.4: The duration indicator shows a color warning when the selected segment exceeds 10 seconds (orange) or 15 seconds (red), with explanatory text.
- AC-04.5: The "Preview Loop" button plays the trimmed segment in a continuous loop. Playback starts from the start handle position and loops back seamlessly.
- AC-04.6: The minimum selectable duration is 0.5 seconds. The handles cannot be dragged closer than this threshold.
- AC-04.7: The maximum selectable duration is 30 seconds. The handles cannot be dragged further apart than this threshold.
- AC-04.8: The "Next" button is disabled until the user has set a trim range (i.e., at least one handle has been moved from its default position, or the video is already ≤30 seconds and the full duration is acceptable).

### 5.5 F-05: GIF Encoding Engine

- AC-05.1: The engine converts a trimmed video segment into a valid animated GIF that plays correctly in iOS Photos, Safari, Discord, iMessage, and Twitter/X.
- AC-05.2: Encoding a 3-second, 480p clip completes in under 5 seconds on an iPhone 13 or newer.
- AC-05.3: The engine applies palette optimization (per-frame or global palette selection) to maximize color quality within the GIF format's 256-color constraint.
- AC-05.4: The engine supports configurable target frame rates. The "Standard" preset targets 12 FPS; "Discord" targets 15 FPS; "High Quality" targets 20 FPS.
- AC-05.5: The encoding process reports progress as a percentage, updating at least every 500ms, which drives the progress indicator UI.

### 5.6 F-07: Camera Roll Export

- AC-06.1: On first export, the app requests Photos write permission using the standard iOS permission dialog.
- AC-06.2: If permission is granted, the GIF is saved to the Photos library and is immediately visible in the Recents album and any animated-image smart album.
- AC-06.3: If permission is denied, the app displays a clear message with a button that deep-links to the app's Settings page.
- AC-06.4: After a successful save, the app plays the finished GIF in a loop and displays the file size and pixel dimensions.
- AC-06.5: The "Share" button on the success screen opens the native iOS share sheet with the GIF pre-attached.

### 5.7 F-08: Freemium Gating

- AC-07.1: Free tier users can export up to 1 GIF per calendar day (midnight-to-midnight, device local time).
- AC-07.2: The daily counter is visible on the success screen after each export ("0 of 1 free GIFs remaining today").
- AC-07.3: When the daily limit is reached, the "Create GIF" button is replaced with an "Upgrade to Premium" prompt. The trim and preview workflows remain fully functional so the user experiences the value before hitting the gate.
- AC-07.4: Premium subscription is offered at one price point: $9.99/year. Managed via StoreKit 2 and Apple's subscription infrastructure.
- AC-07.5: Restoring a purchase on a new device correctly unlocks premium features.

### 5.8 F-09: Watermark (Free Tier)

- AC-08.1: On the free tier, a semi-transparent ClipForge logomark (PNG asset, swappable when final branding is complete) is rendered in the bottom-right corner at 40–50% opacity, approximately 10–15% of frame width, on every GIF frame.
- AC-08.2: The watermark is legible but unobtrusive — it should not cover faces or critical content in the center of the frame.
- AC-08.3: The watermark is absent on all GIFs created by premium users.
- AC-08.4: The watermark is embedded during encoding (not overlaid on the player); it is part of the final file and cannot be removed by the user without upgrading.

### 5.9 F-10: Error Handling and Status Feedback

- AC-09.1: Every user-facing error message is written in plain language. No HTTP status codes, no technical jargon, no raw error strings.
- AC-09.2: Every error state has a clear recovery action (retry, change input, check settings, contact support).
- AC-09.3: The loading indicator during video import is a progress ring on the CREATE GIF button — indeterminate animation during extraction, determinate vermillion stroke during video download. No separate spinner or loading screen. No use of the word "Downloading."
- AC-09.4: If the backend is unreachable for more than 5 seconds, the app shows "Having trouble reaching our servers. Check your connection and try again."
- AC-09.5: If yt-dlp fails for a specific platform, the error message names the platform: "We can't get videos from [Platform] right now. This usually fixes itself quickly."

### 5.10 F-11: Onboarding Flow

- AC-10.1: On first launch, the app displays a three-screen onboarding walkthrough: (1) "Copy a link from your favorite social app," (2) "Trim to the perfect moment," (3) "Export a GIF in seconds."
- AC-10.2: Each screen has a simple illustration and one sentence of copy.
- AC-10.3: The walkthrough is skippable via a "Skip" button visible on every screen.
- AC-10.4: After completing or skipping onboarding, the user lands on the home screen. The onboarding does not repeat on subsequent launches.

### 5.11 F-12: Privacy and Legal Compliance

- AC-11.1: The app collects zero personal data. No analytics SDK, no user accounts, no tracking identifiers.
- AC-11.2: A privacy policy is accessible from the app's Settings screen and from the App Store listing.
- AC-11.3: An in-app copyright disclaimer is visible in Settings: "ClipForge is intended for personal, non-commercial use of content you have the right to use."
- AC-11.4: The App Store privacy nutrition label accurately reflects zero data collection.
- AC-11.5: The app does not include any third-party SDKs that collect data (no Firebase Analytics, no Crashlytics, no ad SDKs in MVP).

## 6. Non-Functional Requirements

### 6.1 Performance Targets

| Metric | Target | Measurement Condition |
|--------|--------|-----------------------|
| Link-to-player time | ≤15 seconds | LTE connection, Twitter/X 720p video under 30s duration |
| Trim handle responsiveness | ≤100ms latency | Frame update after handle drag on iPhone 13 or newer |
| GIF encoding time (3s clip, Standard preset) | ≤5 seconds | iPhone 13 or newer |
| GIF encoding time (10s clip, High Quality preset) | ≤20 seconds | iPhone 13 or newer |
| App launch to home screen | ≤2 seconds | Cold launch, iPhone 13 or newer |
| Memory footprint during encoding | ≤300 MB peak | 10-second 720p source clip |

### 6.2 Compatibility

- Minimum iOS version: iOS 17.0. This covers approximately 90%+ of active iPhones and ensures access to current SwiftUI features, StoreKit 2, and PHPhotoLibrary APIs.
- Minimum device: iPhone 12. Older devices may function but are not tested or supported.
- iPad: The app should function on iPad but is not optimized for iPad layouts in MVP. Standard iPhone-app-on-iPad scaling is acceptable.
- Orientation: Portrait only for MVP.

### 6.3 Offline Behavior

- Video import requires an internet connection (the backend API is server-side). The app displays a clear message when offline: "Connect to the internet to import videos."
- If a video has already been imported and loaded into the player, the trim and GIF encoding workflows function fully offline. No additional network calls are made after import.
- GIF export to the camera roll functions offline.
- The daily free-tier counter is stored locally and does not require a network connection to enforce.

### 6.4 Accessibility

- All interactive elements have accessibility labels.
- The trim handles support VoiceOver with spoken position ("Start: 2.3 seconds. End: 5.1 seconds. Duration: 2.8 seconds.").
- Dynamic Type is respected for all text elements.
- Minimum touch target size for all interactive controls: 44×44 points (Apple Human Interface Guidelines).

### 6.5 Localization

- MVP launches in English only.
- All user-facing strings are externalized into a Localizable.strings file to support future localization without code changes.

## 7. Success Metrics

These define what "working" means for the MVP launch on the App Store.

**Functional success (must be true before App Store submission):**
- A user can paste a supported URL from each of the five platforms (Twitter/X, Instagram, Reddit, TikTok, Twitch) and produce a GIF exported to the camera roll in a single session, without leaving the app.
- The full workflow (paste → import → trim → export) completes in under 60 seconds for a 3-second clip on LTE. The target is under 30 seconds, but 60 seconds is the acceptance threshold.
- The exported GIF plays correctly when shared via iMessage, Discord, and Twitter/X.
- The freemium gate correctly limits free users to 1 export per day and correctly unlocks unlimited access for premium subscribers.
- Zero crashes during the core workflow in 50 consecutive test runs across three different device models.

**Launch success (measured in the first 90 days after App Store approval):**
- App Store approval on first or second submission.
- 1,000+ downloads in the first 30 days (organic, no paid acquisition).
- 50+ premium conversions in the first 90 days (5% conversion rate target).
- App Store rating of 4.0+ with at least 20 reviews.
- Zero App Store compliance incidents (no removal, no warnings).

**Signals to watch (not pass/fail, but informative):**
- Percentage of users who complete the full workflow on first session (target: 70%+).
- Average GIFs created per active user per week.
- Most-used platform (which social media source generates the most imports).
- Free tier users who hit the daily limit (indicates demand for premium).
