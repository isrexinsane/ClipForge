---
title: "ClipForge — Screen Inventory"
agent: PM
phase: Planning (Phase 5 Wrap-Up)
status: Complete
date: 2026-04-12
project: ClipForge
org: Ronin Art House
depends_on:
  - CLAUDE.md
  - PRD.md
  - Epic_Breakdown.md
  - Session_Handoff_2026-04-11_v2.md
  - Supplemental_Handoff_2026-04-12.md
---

# ClipForge — Screen Inventory

This document maps every user-facing screen and state to its Figma reference, implementing epic, visual specifications, and interaction behavior. The BMAD Scrum Master agent uses this as the authoritative reference when writing stories that involve UI implementation.

---

## Screen 01: Home

**Figma frame:** 01 - Home
**Implementing epic:** Epic 1 (Project Scaffolding), Epic 3 (Networking + Video Import)
**Completion:** ~85% designed

### Visual Specification

| Element | Spec |
|---------|------|
| Background | `F5F0EB` (warm off-white shell) |
| Gradient | Linear, top-to-bottom, `EF3340` at 100% opacity → `EF3340` at 0% opacity, reaches ~50% down the screen |
| App title | "CLIPFORGE" — JetBrains Mono Medium ~18px, `F5F0EB` (warm white), top-left |
| Menu button | "+" icon, Liquid Glass style, top-right. Opens iOS context menu: Restore Purchase, Privacy Policy, About ClipForge |
| CTA button | Large centered circle, vermillion (`EF3340`). Concave/depth treatment TBD (currently flat placeholder). Border doubles as progress ring during video import |
| CTA label | "CREATE GIF" — JetBrains Mono Medium ~16px, `382F2D`, centered below button |
| Platform list | "X · Instagram · Reddit · TikTok · Twitch" — Inter Regular ~12px, `968C83`, centered below CTA label |
| Page indicator | Two dots, bottom-center. Home state: large black dot (10×10) left, small grey dot (6×6, `968C83`) right. CAVA-style stretch animation on swipe |

### States

| State | Trigger | Behavior |
|-------|---------|----------|
| Default | App launch, no URL on clipboard | CTA button at rest, standard appearance |
| URL detected | Supported URL found on clipboard (iOS paste disclosure approved) | CTA button state changes to indicate readiness. Tapping triggers video import |
| Loading (import) | User taps CTA with URL detected | Button border becomes vermillion progress ring. Indeterminate animation during extraction API call (2-8s), determinate progress during video file download. Label may change to "PREPARING..." |
| Import error | Backend returns error | Progress ring resets. Error message appears below platform list per PRD F-10 specs |
| Import success | Video fully downloaded | Transition to Trim Modal (Frame 03) as full-screen modal sheet |

### Epic/Story Mapping

| Component | Epic | Notes |
|-----------|------|-------|
| Screen layout, navigation structure, MVVM scaffolding | Epic 1 | NavigationStack, HomeView, placeholder content |
| CTA button (static) | Epic 1 | Visual element, no functionality |
| Page indicator + swipe to Media Library | Epic 1 | Two-page horizontal scroll with dot indicator |
| Menu button + context menu | Epic 1 | Restore Purchase, Privacy Policy, About |
| Clipboard detection | Epic 3 | ClipboardMonitor, SupportedPlatforms regex, paste disclosure handling |
| CTA button import trigger + progress ring | Epic 3 | APIService call, URLSession download progress, ring animation |
| Error state display | Epic 3 / Epic 10 | Error mapping from ClipForgeAPIError to user-facing strings |

---

## Screen 02: Media Library

**Figma frame:** 02 - Media Library
**Implementing epic:** Epic 6 (Camera Roll Export — partial), Epic 9 (Onboarding — sequenced late)
**Completion:** ~70% designed

### Visual Specification

| Element | Spec |
|---------|------|
| Background | `F5F0EB` (same as Home) |
| Gradient | Same vermillion linear gradient as Home |
| Page title | "GALLERY" — JetBrains Mono Medium ~18px, `F5F0EB`, top-left |
| Grid layout | Masonry grid — asymmetric tile sizes (large tile left, two shorter stacked right, alternating). Liquid Glass frosted cards |
| Card opacity | Cards fade in opacity toward bottom of scroll (scroll-depth illusion) |
| Page indicator | Inverse of Home: small grey dot left, large black dot right |
| Empty state | Not yet designed. Needed: message like "Your GIFs will appear here" when no GIFs exist |

### States

| State | Trigger | Behavior |
|-------|---------|----------|
| Empty | No GIFs created yet | Empty state message, possibly with illustration |
| Populated | One or more GIFs in history | Masonry grid of GIF thumbnails |
| Tile tap | User taps a GIF tile | iOS share sheet opens immediately with selected GIF attached. No in-app detail view |

### Epic/Story Mapping

| Component | Epic | Notes |
|-----------|------|-------|
| Screen layout, swipe navigation from Home | Epic 1 | Second page of horizontal scroll |
| GIF thumbnail grid | Epic 6 | After successful export, GIF appears in library. Requires local storage of GIF references |
| Tile tap → share sheet | Epic 6 | UIActivityViewController with GIF data |
| Empty state design | Epic 9 or Epic 10 | Low priority, can be simple text |

---

## Screen 03: Trim Modal

**Figma frame:** 03 - Trim Modal
**Implementing epic:** Epic 3 (video player), Epic 4 (trim interface), Epic 5 (encoding trigger)
**Completion:** ~75% designed

### Visual Specification

| Element | Spec |
|---------|------|
| Background | `000000` (pure black), matching iOS Photos/Camera editor |
| Presentation | Full-screen modal sheet, slides up from bottom. Dismissible via Cancel button or swipe-down |
| Volume button | Top-left. Liquid Glass Symbol button with `speaker.wave.2.fill` SF Symbol. Toggles audio mute on video playback |
| Cancel button | Top-right. Liquid Glass Text button, label "Cancel". Dismisses modal, returns to Home |
| Video area | Center of screen, edge-to-edge width, no rounded corners, no padding. Black letterboxing above/below for non-matching aspect ratios. Fill color placeholder: white (will be replaced by actual video content) |
| Trim bar | iOS Photos-style. See Trim Bar detail table below |
| Duration readout | "2.4s" — JetBrains Mono Bold 32px, `FFFFFF`, centered below trim bar |
| CREATE button | Pill capsule, currently compact. Spec calls for W: 400, H: 52, corner radius 26, fill `EF3340`, text "CREATE" in JetBrains Mono Medium 16px, `FFFFFF`. Centered below duration readout |

### Trim Bar Detail

| Element | Spec |
|---------|------|
| Container | Single rounded rectangle, ~400px wide × 56px tall, corner radius 10, fill `3A3A3C` |
| Play button section | Left ~50px of container, separated by 1px vertical divider (`2C2C2E`). Contains `play.fill` SF Symbol in white, centered |
| Filmstrip | Single solid rectangle filling remaining width, fill `4A4A4C`. Represents video frame thumbnails (actual thumbnails generated from AVAsset at runtime) |
| Left chevron handle | 16px wide × 56px tall, fill `FFFFFF` at 30% opacity, corner radius 10 on top-left and bottom-left only. Contains `chevron.compact.left` SF Symbol in white, centered |
| Right chevron handle | Mirror of left. Corner radius on top-right and bottom-right. Contains `chevron.compact.right` |
| Selection border | 2-3px horizontal lines connecting top and bottom edges of left and right handles. Fill `FFFFFF` at 30% opacity |
| Playhead | 3px wide × 56px tall vertical line, `FFFFFF` solid. Small rounded nub (12×5, corner radius 2.5) at top. Draggable |

### States

| State | Trigger | Behavior |
|-------|---------|----------|
| Trim (default) | Modal opens with video loaded | Video plays in player. Trim handles draggable. Duration updates in real time. Play button triggers preview loop of trimmed segment |
| Encoding progress | User taps CREATE | CREATE button transforms into circular progress ring (vermillion stroke, `EF3340`). Percentage in JetBrains Mono Bold, white, centered. "Creating your GIF..." text below in JetBrains Mono Medium ~14px, `968C83`. Trim bar and duration remain visible. Cancel button still active (aborts encoding) |
| Export success | Encoding complete, GIF saved | Video area becomes looping GIF preview. Trim bar disappears. File size + dimensions readout appears (e.g., "3.2 MB · 480 × 270", JetBrains Mono Medium ~14px, white). Share button (vermillion pill) and Done button (white outline pill) appear below. Free tier: "0 of 1 free GIFs remaining today" in `968C83` above buttons |
| Freemium gate | Free tier limit reached (1/day) | CREATE button replaced with "Upgrade to Premium" prompt. Trim and preview still functional so user experiences value before hitting the gate |

### Epic/Story Mapping

| Component | Epic | Notes |
|-----------|------|-------|
| Modal presentation + dismiss | Epic 1 | Full-screen modal sheet, navigation structure |
| Video player (AVPlayer, AVURLAsset) | Epic 3 | VideoPlayerManager, video loads from cached file |
| Volume toggle | Epic 3 | Mute/unmute audio on AVPlayer |
| Trim handles (drag, seek, frame-accurate) | Epic 4 | TrimViewModel, AVPlayer.seek with zero tolerance. Evaluate VideoTrimmerControl repo for integration |
| Duration readout (real-time update) | Epic 4 | Computed property: endTime - startTime, formatted to 1 decimal |
| Play button (preview loop) | Epic 4 | Plays trimmed segment in continuous loop |
| Timeline filmstrip thumbnails | Epic 4 | AVAssetImageGenerator generates frame thumbnails at runtime |
| Playhead (draggable scrubber) | Epic 4 | Progress indicator + scrub gesture |
| CREATE button + encoding trigger | Epic 5 | Initiates GIFEncoder pipeline |
| Encoding progress ring | Epic 5 | Frame-count-based percentage, circular progress animation |
| GIF encoding (auto-optimized ≤8 MB) | Epic 5 | ImageIO/CoreGraphics pipeline, batch frame processing |
| Watermark compositing (free tier) | Epic 7 | Logomark PNG composited via CoreGraphics during encoding |
| Camera roll save | Epic 6 | PHPhotoLibrary, permission request on first export |
| Export success state (GIF preview, share, done) | Epic 6 | In-modal state change, UIActivityViewController for share |
| Freemium gate + daily counter | Epic 7 | FreemiumGatekeeper, UserDefaults (1/day), counter display |
| Subscription prompt | Epic 8 | "Upgrade to Premium" triggers SubscriptionView |

---

## Screen 04: Encoding Progress (State Within Trim Modal)

**Figma frame:** 04 - Encoding Progress (state within Trim Modal)
**Implementing epic:** Epic 5 (GIF Encoding Engine)
**Completion:** Specified in handoff docs, no separate Figma design needed

This is NOT a separate screen. It is a state change within Frame 03 (Trim Modal). See the "Encoding progress" state row in the Trim Modal states table above. The Figma frame exists as a labeled placeholder only.

---

## Screen 05: Export Success (State Within Trim Modal)

**Figma frame:** 05 - Export Success (state within Trim Modal)
**Implementing epic:** Epic 6 (Camera Roll Export), Epic 7 (Freemium Gating)
**Completion:** Specified in handoff docs, no separate Figma design needed

This is NOT a separate screen. It is a state change within Frame 03 (Trim Modal). See the "Export success" state row in the Trim Modal states table above. The Figma frame exists as a labeled placeholder only.

---

## Non-Screen UI: Onboarding Flow

**Figma frame:** None (standard iOS pattern, no mockup needed)
**Implementing epic:** Epic 9 (Onboarding Flow)

Three-screen paged walkthrough on first launch:

1. "Copy a link from your favorite social app" — illustration + one sentence
2. "Trim to the perfect moment" — illustration + one sentence
3. "Export a GIF in seconds" — illustration + one sentence

Skip button visible on every screen. "Get Started" on final screen. `hasCompletedOnboarding` flag in UserDefaults prevents repeat. Visual language inherits from Home screen: warm off-white background, vermillion accent, JetBrains Mono typography.

---

## Non-Screen UI: Subscription Prompt

**Figma frame:** None (standard iOS pattern, no mockup needed)
**Implementing epic:** Epic 8 (In-App Subscriptions)

Accessible from: freemium gate on Trim Modal, menu button → Restore Purchase. Single product: $9.99/year. StoreKit 2. Includes links to Privacy Policy and Terms of Service.

---

## Non-Screen UI: Permission Dialogs

**Figma frame:** None (system dialogs)
**Implementing epic:** Epic 3 (clipboard paste disclosure), Epic 6 (Photos library write permission)

These are standard iOS system dialogs. No custom design needed. The app provides the usage description strings in Info.plist that appear in the dialog text.

---

## Summary: Epic-to-Screen Coverage

| Epic | Screens Touched |
|------|----------------|
| Epic 1: Project Scaffolding | Home, Media Library, Trim Modal (structure only) |
| Epic 2: Backend API | None (server-side only) |
| Epic 3: Networking + Video Import | Home (clipboard detection, loading ring), Trim Modal (video player, volume toggle) |
| Epic 4: Trim Interface | Trim Modal (handles, seek, duration, preview loop, filmstrip, playhead) |
| Epic 5: GIF Encoding Engine | Trim Modal (encoding progress state) |
| Epic 6: Camera Roll Export | Trim Modal (export success state), Media Library (GIF thumbnail grid, tile → share sheet) |
| Epic 7: Freemium Gating + Watermark | Trim Modal (freemium gate state, daily counter, watermark during encoding) |
| Epic 8: Subscriptions | Subscription prompt (non-screen UI) |
| Epic 9: Onboarding Flow | Onboarding walkthrough (non-screen UI) |
| Epic 10: Error Handling Polish | Home (error states), Trim Modal (error states) |
| Epic 11: App Store Preparation | None (metadata, screenshots, submission) |
