---
title: "ClipForge — Epic 4 Stories (Approved)"
agent: SM (Scrum Master)
phase: Development
status: Approved — Ready for Implementation
date: 2026-04-12
project: ClipForge
org: Ronin Art House
epic: "Epic 4 — Trim Interface"
depends_on:
  - Architecture_Spec.md
  - API_Contract.md
  - Screen_Inventory.md
  - CLAUDE.md
  - Epic3_Stories_Approved.md
sprint: Sprint 2
---

# Epic 4 — Trim Interface

## Implementation Order

Implement sequentially. Each story builds on the previous. Test in the simulator before moving to the next.

1. STORY-014: TrimViewModel — Core Trim State Management
2. STORY-015: Filmstrip Thumbnail Generator
3. STORY-016: TrimBarView — Timeline Scrubber UI
4. STORY-017: Duration Readout and Color Warnings
5. STORY-018: CREATE Button and Next-Step Trigger (includes font file setup)

**Reference repo:** `github.com/AndreasVerhoeven/VideoTrimmerControl` — MIT-licensed UIKit trim control. Use as architectural reference for drag gesture handling, thumbnail generation patterns, and zoom-on-trim behavior. Do NOT import as a dependency — build native SwiftUI.

---

## STORY-014: TrimViewModel — Core Trim State Management

**Epic:** 4 — Trim Interface
**Priority:** Must-have
**Depends on:** STORY-013 (VideoPlayerManager exists, Trim Modal shell exists)

**As a** ClipForge user,
**I want** the app to track my trim selection precisely,
**so that** the GIF I export is exactly the segment I chose.

### Implementation Context

Create `TrimViewModel.swift` in the ViewModels folder. This is the brain of the trim interface — it owns the trim range state, computes duration, enforces constraints, and drives the player's seek position when handles move.

**Published properties:**

```swift
@Published var startTime: Double = 0.0      // seconds from beginning
@Published var endTime: Double              // initialized to video duration
@Published var trimDuration: Double         // computed: endTime - startTime
@Published var durationText: String         // formatted: "2.4s"
@Published var durationColor: DurationColor // .normal, .warning, .danger
@Published var isNextEnabled: Bool = false  // true once user has set a trim range
@Published var isPreviewLooping: Bool = false
```

**DurationColor enum:**

```swift
enum DurationColor {
    case normal    // ≤10 seconds — white text
    case warning   // >10 and ≤15 seconds — orange
    case danger    // >15 seconds — red, with "Long clips produce large files" note
}
```

**Constraints (PRD AC-04.6, AC-04.7):**
- Minimum trim duration: 0.5 seconds
- Maximum trim duration: 30 seconds
- `isNextEnabled` true when at least one handle moved from default, OR source video ≤30 seconds

**Methods:**

- `updateStartTime(_ time: Double)` — clamps to valid range, updates computed properties
- `updateEndTime(_ time: Double)` — clamps to valid range, updates computed properties
- `seekToStart()` — tells VideoPlayerManager to seek to startTime with zero tolerance
- `seekToEnd()` — same for end handle
- `startPreviewLoop()` — loops playback between startTime and endTime
- `stopPreviewLoop()` — stops looping

**Integration with VideoPlayerManager:** Holds reference to VideoPlayerManager. Calls `player.seek(to: CMTime, toleranceBefore: .zero, toleranceAfter: .zero)` on handle moves. Preview loop uses boundary time observer that seeks back to startTime when playback reaches endTime.

### Acceptance Criteria

- [ ] startTime=2.0 + endTime=5.0 → trimDuration=3.0, durationText="3.0s"
- [ ] 12-second range → durationColor `.warning`
- [ ] 16-second range → durationColor `.danger`
- [ ] Cannot set start and end closer than 0.5s apart (clamped)
- [ ] Cannot set range wider than 30s (clamped)
- [ ] `isNextEnabled` true when at least one handle moved from default
- [ ] `isNextEnabled` true by default when source video ≤30 seconds
- [ ] Preview loop plays trimmed segment and loops back to startTime seamlessly

---

## STORY-015: Filmstrip Thumbnail Generator

**Epic:** 4 — Trim Interface
**Priority:** Must-have
**Depends on:** STORY-013 (VideoPlayerManager provides AVURLAsset)

**As a** ClipForge user,
**I want** to see frame thumbnails along the timeline,
**so that** I can visually identify the moment I want to trim to.

### Implementation Context

Create `FilmstripGenerator.swift` in the Services folder. Extracts evenly-spaced frame thumbnails from the video.

**Behavior:**
- Accepts `AVURLAsset` and target thumbnail count (default: 8–10 based on available width)
- Uses `AVAssetImageGenerator` to extract frames at evenly-spaced timestamps
- `requestedTimeToleranceBefore`/`toleranceAfter` = 0.1s (speed over accuracy for thumbnails)
- Returns array of `UIImage` or `CGImage` scaled to ~44×44 points
- Generates asynchronously — publishes frames progressively as they become available
- Memory: 8–10 thumbnails at 44×44 ≈ 50 KB total. Negligible.

### Acceptance Criteria

- [ ] 14-second video produces 8–10 evenly-spaced thumbnails
- [ ] Thumbnails appear progressively (not all at once after delay)
- [ ] Thumbnails maintain video aspect ratio (cropped to square or letterboxed)
- [ ] Generation completes within 1 second for typical 720p 30-second source
- [ ] No UI hang during generation (async execution)

---

## STORY-016: TrimBarView — Timeline Scrubber UI

**Epic:** 4 — Trim Interface
**Priority:** Must-have
**Depends on:** STORY-014 (TrimViewModel), STORY-015 (FilmstripGenerator)

**As a** ClipForge user,
**I want** a visual timeline with draggable trim handles,
**so that** I can select exactly the segment I want.

### Implementation Context

Create `TrimBarView.swift` in the Views folder. Custom SwiftUI view matching the Figma trim bar design and iOS Photos editor pattern.

**Layout (left to right within one rounded rectangle, `3A3A3C`, corner radius 10):**

1. **Play button section** (~50px): Separated by 1px divider. SF Symbol `play.fill`/`pause.fill`. Tap toggles preview loop.
2. **Filmstrip area**: Thumbnails from FilmstripGenerator in horizontal row.
3. **Left chevron handle**: 16px wide, full height, `FFFFFF` at 30% opacity, `chevron.compact.left` centered. Corner radius on outer corners only. Draggable via DragGesture → updates TrimViewModel.startTime.
4. **Right chevron handle**: Mirror of left. `chevron.compact.right`. Updates endTime.
5. **Selection border**: 2-3px lines connecting top/bottom edges of handles. `FFFFFF` at 30% opacity.
6. **Dimming**: Area outside trim selection overlaid with `Color.black.opacity(0.6)`.
7. **Playhead**: 3px wide white vertical line + rounded nub at top. Position driven by VideoPlayerManager.currentTime. Also draggable for scrubbing.

**Drag gesture handling:**
- Left handle: maps horizontal position to video time. Clamped by min duration (0.5s) and min position (0.0).
- Right handle: maps horizontal position to video time. Clamped by min duration from startTime and max 30s.
- Playhead: scrubs VideoPlayerManager to corresponding time. Does not affect trim range.
- Use `.gesture(DragGesture(minimumDistance: 0))` to eliminate drag delay. Target: ≤100ms responsiveness.

### Acceptance Criteria

- [ ] Trim bar renders with play button, filmstrip, chevron handles, and playhead
- [ ] Left handle drag updates start time + player seeks to that frame
- [ ] Right handle drag updates end time + player seeks to that frame
- [ ] Handle responsiveness ≤100ms (no perceptible lag)
- [ ] Handles cannot go closer than 0.5s apart
- [ ] Handles cannot go further than 30s apart
- [ ] Area outside trim selection is visually dimmed
- [ ] Playhead reflects current playback time during preview loop
- [ ] Playhead is draggable for scrubbing (independent of handles)
- [ ] Play button toggles preview loop on/off

---

## STORY-017: Duration Readout and Color Warnings

**Epic:** 4 — Trim Interface
**Priority:** Must-have
**Depends on:** STORY-014 (TrimViewModel provides durationText and durationColor)

**As a** ClipForge user,
**I want** to see how long my trimmed clip is and be warned if it's too long,
**so that** I can make informed decisions about my GIF's length and file size.

### Implementation Context

Update `TrimModalView.swift` to add duration readout below the trim bar.

**Elements:**

1. **Duration text:** Bound to TrimViewModel.durationText. JetBrains Mono Bold 32px, centered.
   - `.normal` (≤10s): white (`FFFFFF`)
   - `.warning` (>10s, ≤15s): orange (`FF9500`)
   - `.danger` (>15s): red (`FF3B30`)

2. **Warning text** (`.danger` only): "Long clips produce large files" — JetBrains Mono Medium 14px, `968C83`, centered below duration. Fade-in animation on appear.

3. **Real-time:** Updates immediately as handles are dragged. No delay.

### Acceptance Criteria

- [ ] Duration displays in "X.Xs" format (one decimal place)
- [ ] Updates in real time as handles dragged
- [ ] 5-second selection → white text
- [ ] 12-second selection → orange text
- [ ] 16-second selection → red text with "Long clips produce large files"
- [ ] Warning fades in/out at danger threshold
- [ ] Font is JetBrains Mono Bold 32px

---

## STORY-018: CREATE Button and Next-Step Trigger

**Epic:** 4 — Trim Interface
**Priority:** Must-have
**Depends on:** STORY-014 (isNextEnabled), STORY-016 (trim bar functional)

**As a** ClipForge user,
**I want** to confirm my trim and proceed to GIF creation,
**so that** I can export my finished GIF.

### Implementation Context

Update `TrimModalView.swift` to add CREATE button below duration readout.

**Button spec:**
- Full-width pill: W matches trim bar width, H: 52px, corner radius 26
- Fill: `EF3340` (vermillion)
- Text: "CREATE" — JetBrains Mono Medium 16px, `FFFFFF`, centered
- Disabled: opacity 0.4, non-tappable. Enabled when `isNextEnabled` is true.

**Behavior:**
- Tapping passes AVURLAsset + CMTimeRange (startTime→endTime) + metadata to encoding pipeline
- For Epic 4: placeholder action — print trim range or show alert: "Ready to encode: [start]s to [end]s ([duration]s)"
- Actual encoding wired in Epic 5

**Font setup (include in this story):**
- Download JetBrains Mono and Inter font families
- Add .ttf files to Xcode project bundle
- Register in Info.plist under "Fonts provided by application"
- Verify fonts render in Trim Modal and Home screen

### Acceptance Criteria

- [ ] CREATE button renders as vermillion pill centered below duration
- [ ] Button disabled (dimmed) until valid trim range set
- [ ] Button enabled when isNextEnabled is true
- [ ] Tapping produces correct trim range values (startTime, endTime, duration)
- [ ] JetBrains Mono and Inter fonts render correctly throughout Trim Modal
- [ ] Button text is "CREATE" — no "download" language anywhere

---

## Done Criteria for Epic 4

Epic 4 is complete when:
1. All five stories pass their acceptance criteria
2. User can drag trim handles on the timeline and see the video seek to the corresponding frame in real time
3. Duration readout updates immediately as handles move with correct color warnings
4. Preview loop plays the trimmed segment seamlessly
5. Filmstrip thumbnails populate from the source video
6. CREATE button is enabled after setting a trim range and outputs correct trim data
7. Fonts (JetBrains Mono, Inter) render correctly throughout the app
