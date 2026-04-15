---
title: "ClipForge — Epic 5 & 6 Stories (Approved)"
agent: SM (Scrum Master)
phase: Development
status: Approved — Ready for Implementation
date: 2026-04-12
project: ClipForge
org: Ronin Art House
epics: "Epic 5 — GIF Encoding Engine, Epic 6 — Camera Roll Export"
depends_on:
  - Architecture_Spec.md
  - API_Contract.md
  - Screen_Inventory.md
  - CLAUDE.md
  - Epic4_Stories_Approved.md
sprint: Sprint 2
---

# Epic 5 — GIF Encoding Engine & Epic 6 — Camera Roll Export

## Implementation Order

Implement sequentially. Epics 5 and 6 are tightly coupled — Epic 5 produces the GIF, Epic 6 saves and displays it.

1. STORY-019: GIFEncoder — Core Frame Extraction and Encoding Pipeline
2. STORY-020: ExportViewModel — Encoding Orchestration and Progress State
3. STORY-021: Camera Roll Save — PHPhotoLibrary Integration
4. STORY-022: Export Success State — GIF Preview, Share, and Done
5. STORY-023: Media Library — GIF History Grid

**Encoding spec reminder:** "Works Everywhere" target is ≤8 MB. If output exceeds 8 MB after two encoding passes, save anyway with a warning. Never block export.

**30s trim / 15s warning reconciliation:** The trim bar allows up to 30s. Danger color kicks in at >15s. The encoder attempts any duration up to 30s with progressively aggressive compression. The user chose to proceed past the warning — respect that choice and inform, don't block.

---

## STORY-019: GIFEncoder — Core Frame Extraction and Encoding Pipeline

**Epic:** 5 — GIF Encoding Engine
**Priority:** Must-have
**Depends on:** STORY-014 (TrimViewModel provides trim range), STORY-013 (VideoPlayerManager provides AVURLAsset)

**As a** ClipForge user,
**I want** my trimmed video segment to become an animated GIF,
**so that** I can share it anywhere.

### Implementation Context

Create `GIFEncoder.swift` in the Services folder. Core engine converting trimmed video to animated GIF using native ImageIO. No third-party dependencies.

**Input:**
- `asset: AVURLAsset`
- `timeRange: CMTimeRange` (startTime to endTime)
- `progressHandler: @escaping (Double) -> Void` (0.0–1.0)

**Output:**
- `Data` — raw GIF file data

**Encoding pipeline:**

1. **Calculate parameters from "Works Everywhere" spec:**
   - Target: ≤8 MB
   - Clips ≤10s: 15 FPS, 640px max width
   - Clips >10s: 12 FPS, 480px max width
   - Clips >20s: 10 FPS, 400px max width

2. **Frame extraction:** `AVAssetImageGenerator` with zero tolerance. Generate timestamps at target FPS within trim range.

3. **Batch processing (20-frame batches per Architecture Spec §8.3):**
   - Extract 20 CGImages
   - Scale each to target max width, maintain aspect ratio
   - Append to CGImageDestination
   - Release batch before next extraction
   - Report progress: `framesProcessed / totalFrames`

4. **GIF assembly:** `CGImageDestination` with type `public.gif`. Global: `kCGImagePropertyGIFLoopCount: 0` (infinite). Per frame: `kCGImagePropertyGIFDelayTime: 1.0 / fps`.

5. **Finalize:** `CGImageDestinationFinalize()` → GIF Data.

6. **Size check:** If >8 MB:
   - Pass 2: reduce FPS by 30%, max width by 20%. Re-encode.
   - If still over: proceed anyway. Valid GIF, just large.

7. **Return** GIF Data.

**Memory budget:** 20 frames × ~1.2 MB at 640px = ~24 MB per batch. Well under 300 MB ceiling.

**Cancellation support:** Check an `isCancelled: Bool` flag between batches. If true, abort and throw a cancellation error.

### Acceptance Criteria

- [ ] 3-second 480p clip encodes to valid animated GIF
- [ ] GIF loops infinitely in iOS Photos
- [ ] GIF plays correctly in Safari
- [ ] 3-second clip encodes in under 5 seconds on iPhone 13+ simulator
- [ ] Progress reports 0.0–1.0, updates at least every 500ms
- [ ] 5-second clip at starting parameters produces GIF ≤8 MB
- [ ] 15-second clip triggers reduced parameters automatically
- [ ] Clip exceeding 8 MB after two passes still produces valid GIF (not blocked)
- [ ] Peak memory under 300 MB during 10-second 720p encode
- [ ] Batch processing releases frames between batches

---

## STORY-020: ExportViewModel — Encoding Orchestration and Progress State

**Epic:** 5 — GIF Encoding Engine
**Priority:** Must-have
**Depends on:** STORY-019 (GIFEncoder), STORY-014 (TrimViewModel)

**As a** ClipForge user,
**I want** to see encoding progress after I tap CREATE,
**so that** I know my GIF is being made and how long it will take.

### Implementation Context

Create `ExportViewModel.swift` in ViewModels folder.

**Published state:**

```swift
enum ExportState {
    case idle
    case encoding(progress: Double)
    case saving
    case success(gifData: Data, fileSize: Int, dimensions: CGSize)
    case error(String)
}

@Published var exportState: ExportState = .idle
@Published var oversizeWarning: String? = nil
```

**Flow:**
1. `.encoding(progress: 0.0)` — CREATE button transforms into progress ring
2. GIFEncoder.encode → progress callback updates state
3. Size check: >8 MB sets `oversizeWarning` with actual size. Proceeds anyway.
4. `.saving` — brief state during PHPhotoLibrary write
5. `.success(gifData:fileSize:dimensions:)` — triggers success UI
6. On failure: `.error("Something went wrong creating the GIF. Try a shorter clip.")`

**TrimModalView integration:**
- `.idle` → CREATE button
- `.encoding` → circular progress ring (vermillion stroke), percentage center, "Creating your GIF..." below
- `.saving` → ring at 100%, "Saving..."
- `.success` → export success state (STORY-022)
- `.error` → error message + "Try Again" resets to `.idle`

**Cancel during encoding:** `isCancelled` flag checked between batches. Cancel button returns to `.idle`.

### Acceptance Criteria

- [ ] CREATE tap transitions to progress ring
- [ ] Ring animates 0%–100% during encoding
- [ ] Percentage text updates in ring center
- [ ] "Creating your GIF..." appears below ring
- [ ] Completion transitions to `.success` with GIF data
- [ ] GIF >8 MB sets `oversizeWarning` with actual file size
- [ ] Encoding error shows message with retry action
- [ ] Cancel during encoding returns to `.idle`
- [ ] Trim bar and duration remain visible during encoding

---

## STORY-021: Camera Roll Save — PHPhotoLibrary Integration

**Epic:** 6 — Camera Roll Export
**Priority:** Must-have
**Depends on:** STORY-020 (ExportViewModel provides GIF data)

**As a** ClipForge user,
**I want** my GIF saved to my camera roll automatically,
**so that** I can share it from anywhere on my phone.

### Implementation Context

Create `ExportManager.swift` in Services folder.

**Permission flow:**
- Check `PHPhotoLibrary.authorizationStatus(for: .addOnly)`
- If `.notDetermined`, request via `PHPhotoLibrary.requestAuthorization(for: .addOnly)`
- If `.authorized`/`.limited`, save
- If `.denied`/`.restricted`: "ClipForge needs access to your photo library to save GIFs. You can enable this in Settings." + button opening `UIApplication.openSettingsURLString`

**Save flow:**
- `PHPhotoLibrary.shared().performChanges`: `PHAssetCreationRequest`, `addResource(with: .photo, data: gifData, options: nil)`
- Return saved asset's local identifier
- On failure, throw with user-facing message

**Wire into ExportViewModel `.saving` state.**

### Acceptance Criteria

- [ ] First export triggers iOS Photos permission dialog
- [ ] After granting permission, GIF saves to Photos
- [ ] Saved GIF visible in Recents album
- [ ] Saved GIF plays as animation in iOS Photos (not static)
- [ ] Permission denied shows message with Settings button
- [ ] Save failure shows error with retry

---

## STORY-022: Export Success State — GIF Preview, Share, and Done

**Epic:** 6 — Camera Roll Export
**Priority:** Must-have
**Depends on:** STORY-021 (ExportManager saves GIF), STORY-020 (ExportViewModel)

**As a** ClipForge user,
**I want** to see my finished GIF and share it immediately,
**so that** I can send it while the moment is still relevant.

### Implementation Context

Update `TrimModalView.swift` for `.success` state.

**Layout (replaces trim interface in same modal):**

1. **GIF preview:** Looping animation. `UIImageView` wrapped in `UIViewRepresentable` with `UIImage.animatedImage(with:duration:)`, or decode frames + `TimelineView`.
2. **Trim bar hidden.**
3. **File info:** "3.2 MB · 480 × 270" — JetBrains Mono Medium 14px, white, centered.
4. **Oversize warning (conditional):** If `oversizeWarning` non-nil, display below file info in `968C83`.
5. **Action buttons (side by side):**
   - **Share:** Vermillion pill (EF3340), "SHARE" white. Opens UIActivityViewController with GIF data.
   - **Done:** Ghost pill (1px white border, no fill), "DONE" white. Dismisses modal.
   - Both ~180px wide, 48px tall, corner radius 24.
6. **Free tier counter placeholder:** "0 of 1 free GIFs remaining today" — JetBrains Mono Medium 13px, `968C83`. Hardcoded visible, non-functional until Epic 7.

**ShareSheet.swift:** `UIViewControllerRepresentable` wrapping `UIActivityViewController`. Initialize with `activityItems: [gifData]`.

### Acceptance Criteria

- [ ] Success state replaces trim interface with GIF preview + buttons
- [ ] GIF loops continuously in preview
- [ ] File size and dimensions display correctly
- [ ] Oversize warning appears if GIF >8 MB
- [ ] Share opens iOS share sheet with GIF attached
- [ ] GIF shared via Messages/AirDrop arrives as animated (not static)
- [ ] Done dismisses modal, returns to Home
- [ ] Free tier counter placeholder visible
- [ ] Trim bar hidden during success state
- [ ] Cancel button acts as secondary dismiss (same as Done)

---

## STORY-023: Media Library — GIF History Grid

**Epic:** 6 — Camera Roll Export
**Priority:** Should-have
**Depends on:** STORY-021 (ExportManager returns saved asset identifier)

**As a** ClipForge user,
**I want** to see my previously created GIFs in the app,
**so that** I can reshare them later.

### Implementation Context

Update Media Library page (Frame 02).

**Storage:** UserDefaults, key `gifHistory`, JSON-encoded array:

```swift
struct GIFHistoryEntry: Codable {
    let id: UUID
    let createdAt: Date
    let fileSize: Int
    let width: Int
    let height: Int
    let localAssetIdentifier: String
}
```

**View:**
- Read gifHistory on appear
- 2-column `LazyVGrid` (or masonry if straightforward, simple grid for MVP)
- Thumbnails via `PHImageManager.default().requestImage(for:)` using stored identifier
- Tile tap → fetch full GIF data → `UIActivityViewController` (share sheet)
- Empty state: "Your GIFs will appear here" — `968C83`, Inter Regular 16px, centered

### Acceptance Criteria

- [ ] Created GIF appears in Media Library on next visit
- [ ] Thumbnails load from Photos via stored asset identifier
- [ ] Tile tap opens share sheet with GIF attached
- [ ] Empty state shows when no GIFs created
- [ ] Grid displays multiple GIFs, scrollable
- [ ] History persists across app launches

---

## Done Criteria for Epics 5 & 6 Combined

Complete when:
1. All 5 stories pass acceptance criteria
2. Full workflow operational: paste URL → import → trim → CREATE → encoding progress → GIF saved to camera roll → success screen with preview, share, done
3. Shared GIFs arrive as animations on receiving end (Messages, AirDrop)
4. Media Library shows previously created GIFs with share-on-tap
5. Oversized GIFs (>8 MB) produce a warning but are not blocked
6. Photos permission flow handles all states (first request, granted, denied)
