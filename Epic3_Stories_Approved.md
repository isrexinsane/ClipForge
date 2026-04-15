---
title: "ClipForge — Epic 3 Stories (Approved)"
agent: SM (Scrum Master)
phase: Development
status: Approved — Ready for Implementation
date: 2026-04-12
project: ClipForge
org: Ronin Art House
epic: "Epic 3 — iOS Networking Layer and Video Import"
depends_on:
  - Architecture_Spec.md
  - API_Contract.md
  - Screen_Inventory.md
  - CLAUDE.md
sprint: Sprint 2
---

# Epic 3 — iOS Networking Layer and Video Import

## Implementation Order

Implement these stories sequentially, one at a time. Each story builds on the previous. Test each in the simulator before moving to the next.

1. STORY-009: APIService — Core Networking Layer
2. STORY-010: ClipboardMonitor — URL Detection
3. STORY-011: HomeViewModel — Import Flow Orchestration
4. STORY-012: HomeView — CTA Button with Progress Ring
5. STORY-013: VideoPlayerManager + Trim Modal Shell

**Backend dependency:** EXTRACT-CONFIG (yt-dlp cookie/proxy config) must be resolved in Railway before end-to-end testing against live social media URLs. Stories 009–010 can be built and tested independently. Stories 011–013 can be built with mocked API responses until EXTRACT-CONFIG is resolved.

---

## STORY-009: APIService — Core Networking Layer

**Epic:** 3 — Networking + Video Import
**Priority:** Must-have
**Depends on:** STORY-001 (Xcode project exists), Epic 2 (backend deployed)

**As a** ClipForge user,
**I want** the app to communicate securely with the ClipForge backend,
**so that** I can import videos from social media URLs.

### Implementation Context

Create `APIService.swift` in the Services folder. This is the single networking class that handles all backend communication. It wraps `URLSession` and provides two async methods.

**Method 1: `extractVideo(url: String) async throws -> ExtractionResponse`**
- Constructs `POST /v1/extract` request per API Contract §3.1
- JSON body: `{"url": "<url>", "max_resolution": "720p", "max_duration": 60}`
- Header: `X-API-Key: <key>` (read from `Configuration.swift`)
- Decodes response into `ExtractionResponse` model
- On error response (4xx/5xx), decodes `ErrorResponse` and throws typed `ClipForgeAPIError`

**Method 2: `downloadMedia(from signedURL: URL, progressHandler: @escaping (Double) -> Void) async throws -> URL`**
- Downloads video file from the signed URL returned by extractVideo
- Saves to app's `Caches` directory with a UUID filename
- Reports download progress (0.0–1.0) via the progressHandler callback
- Returns local file URL
- No `X-API-Key` header needed (signed URL authenticates itself)

**Supporting models (create in Models folder):**

```swift
struct ExtractionResponse: Codable {
    let status: String
    let platform: String
    let videoURL: String
    let duration: Double
    let width: Int
    let height: Int
    let fileSize: Int
    let contentType: String
    let title: String?
}

struct ErrorResponse: Codable {
    let status: String
    let errorCode: String
    let message: String
    let retryAfter: Int?
}
```

Use `JSONDecoder().keyDecodingStrategy = .convertFromSnakeCase`.

**Error enum:**

```swift
enum ClipForgeAPIError: Error {
    case unsupportedPlatform
    case invalidURL
    case videoTooLong
    case extractionFailed
    case extractionTimeout
    case platformUnavailable
    case rateLimited(retryAfter: Int)
    case unauthorized
    case serverError
    case invalidToken
    case expiredMedia
    case mediaNotFound
    case networkUnavailable
    case unknown(statusCode: Int, message: String)
}
```

**Configuration.swift:** Simple struct providing base URL and API key. Staging URL: `https://clipforge-production-f27b.up.railway.app/v1`. API key: read from environment or hardcode with `// TODO: move to xcconfig`.

**Retry logic (Architecture Spec §8.4):** `extractVideo` retries up to 2 times with exponential backoff (2s, 4s) for transient errors (EXTRACTION_TIMEOUT, SERVER_ERROR, networkUnavailable). Non-transient errors are not retried. RATE_LIMITED is not retried — surface `retryAfter` to the caller.

### Acceptance Criteria

- [ ] `APIService` compiles with zero warnings
- [ ] `ClipForgeAPIError` enum covers all 12 error codes from API Contract §4
- [ ] `extractVideo` sends correct JSON body and headers to the staging URL
- [ ] `downloadMedia` saves a file to Caches and returns a valid local file URL
- [ ] `downloadMedia` reports progress values between 0.0 and 1.0 via the callback
- [ ] Retry logic retries EXTRACTION_TIMEOUT up to 2 times with 2s/4s delays
- [ ] Retry logic does NOT retry UNSUPPORTED_PLATFORM or INVALID_URL
- [ ] All JSON keys correctly map between snake_case (API) and camelCase (Swift)

---

## STORY-010: ClipboardMonitor — URL Detection

**Epic:** 3 — Networking + Video Import
**Priority:** Must-have
**Depends on:** STORY-001 (Xcode project exists)

**As a** ClipForge user,
**I want** the app to detect when I've copied a supported social media URL,
**so that** I can import a video with one tap instead of manually pasting.

### Implementation Context

Create `ClipboardMonitor.swift` in the Services folder. This class checks `UIPasteboard.general` for supported URLs when the app enters the foreground.

**SupportedPlatforms.swift** — regex patterns for all five platforms per API Contract §5:

- Twitter/X: `twitter.com/{user}/status/{id}`, `x.com/{user}/status/{id}`, `mobile.twitter.com/{user}/status/{id}`, `t.co/{shortcode}`
- Instagram: `instagram.com/reel/{id}/`, `instagram.com/p/{id}/`, `instagram.com/stories/{user}/{id}/`
- Reddit: `reddit.com/r/{sub}/comments/{id}/{slug}/`, `v.redd.it/{id}`, `old.reddit.com/...`
- TikTok: `tiktok.com/@{user}/video/{id}`, `vm.tiktok.com/{shortcode}`, `tiktok.com/t/{shortcode}/`
- Twitch: `clips.twitch.tv/{slug}`, `twitch.tv/{channel}/clip/{slug}`

YouTube URLs (youtube.com, youtu.be, m.youtube.com) must be explicitly detected and rejected.

**ClipboardMonitor behavior:**
- `@Published var detectedURL: URL?`
- `@Published var detectedPlatform: String?` (e.g., "Twitter/X", "Instagram")
- `@Published var isYouTubeURL: Bool = false`
- On `scenePhase` change to `.active`, reads `UIPasteboard.general.string`
- iOS 16+ triggers system paste disclosure banner — this is expected and correct
- If string matches a supported pattern → set detectedURL and detectedPlatform
- If string matches YouTube → set isYouTubeURL = true, detectedURL = nil
- If no match → all properties nil/false

### Acceptance Criteria

- [ ] Copying a `twitter.com` status URL and opening the app sets `detectedURL` and `detectedPlatform` to "Twitter/X"
- [ ] Copying an `x.com` status URL works identically
- [ ] Copying an Instagram reel URL sets `detectedPlatform` to "Instagram"
- [ ] Copying a YouTube URL sets `isYouTubeURL` to true and `detectedURL` to nil
- [ ] Copying non-URL text results in all properties being nil/false
- [ ] System paste disclosure banner appears on iOS 16+ (correct behavior)
- [ ] Dismissing paste disclosure does NOT clear the clipboard
- [ ] Pattern matching covers at least 3 URL variations per platform

---

## STORY-011: HomeViewModel — Import Flow Orchestration

**Epic:** 3 — Networking + Video Import
**Priority:** Must-have
**Depends on:** STORY-009 (APIService), STORY-010 (ClipboardMonitor)

**As a** ClipForge user,
**I want** to tap the CREATE GIF button and see my video load,
**so that** I can start trimming immediately.

### Implementation Context

Create or update `HomeViewModel.swift`. Orchestrates the full import flow.

**Published state:**

```swift
enum ImportState {
    case idle
    case urlDetected(url: URL, platform: String)
    case youtubeDetected
    case extracting
    case downloading(progress: Double)
    case success(localVideoURL: URL, metadata: ExtractionResponse)
    case error(ClipForgeAPIError)
}

@Published var importState: ImportState = .idle
```

**Import flow (CTA button tap):**

1. Set state to `.extracting`
2. Call `APIService.extractVideo(url:)` — indeterminate progress ring
3. On success, set state to `.downloading(progress: 0.0)`
4. Call `APIService.downloadMedia(from:progressHandler:)` — callback updates progress
5. On download complete, set state to `.success(localVideoURL:metadata:)` — triggers Trim Modal
6. On any error, set state to `.error(error)` — HomeView shows user-facing message

**Error-to-message mapping:** Map `ClipForgeAPIError` cases to user-facing strings from API Contract §4. No string contains the word "download." Store in `Localizable.strings`.

### Acceptance Criteria

- [ ] Tapping CTA with supported URL on clipboard triggers the full import flow
- [ ] During `.extracting`, the UI reflects indeterminate loading
- [ ] During `.downloading`, the UI reflects determinate progress (0%–100%)
- [ ] On success, Trim Modal presents with the video file URL
- [ ] On `UNSUPPORTED_PLATFORM`, correct message appears naming supported platforms
- [ ] On YouTube URL, specific message: "YouTube isn't supported to keep ClipForge available on the App Store."
- [ ] On network unavailable: "No internet connection..."
- [ ] No user-facing string contains the word "download"
- [ ] After error, user can retry

---

## STORY-012: HomeView — CTA Button with Progress Ring

**Epic:** 3 — Networking + Video Import
**Priority:** Must-have
**Depends on:** STORY-011 (HomeViewModel)

**As a** ClipForge user,
**I want** to see the CREATE GIF button visually show import progress,
**so that** I know something is happening while I wait.

### Implementation Context

Update `HomeView.swift` to bind CTA button appearance to `HomeViewModel.importState`.

**Visual states:**

| ImportState | Button Appearance |
|-------------|-------------------|
| `.idle` | Static circle, vermillion (`EF3340`). "CREATE GIF" label below: JetBrains Mono Medium ~16px, `382F2D` |
| `.urlDetected` | Subtle glow or pulse. Optional: "Create from [Platform]" below |
| `.extracting` | Indeterminate ring — rotating partial arc of vermillion stroke |
| `.downloading(progress)` | Determinate ring — `Circle().trim(from: 0, to: progress)` vermillion stroke, clockwise from 12 o'clock |
| `.success` | Full ring, brief completion animation, then Trim Modal presents |
| `.error` | Ring resets. Error text appears below platform list: `968C83`, Inter Regular ~14px |

**SwiftUI:** Progress ring is a `Circle()` with `.stroke(style:)` overlay. `trim(from:to:)` drives determinate progress. Indeterminate state uses `rotationEffect` with repeating animation on partial arc.

### Acceptance Criteria

- [ ] Button renders in `.idle` state on launch with no URL on clipboard
- [ ] Button visually changes when supported URL detected on clipboard
- [ ] Tapping in `.urlDetected` state starts import flow
- [ ] During extraction: spinning/rotating indeterminate animation
- [ ] During download: clockwise-filling progress ring
- [ ] At 100%: brief completion animation before modal presents
- [ ] On error: button returns to default, error text appears below
- [ ] Error text never contains the word "download"
- [ ] Button is tappable in `.idle` and `.urlDetected`, non-tappable during `.extracting`/`.downloading`

---

## STORY-013: VideoPlayerManager + Trim Modal Shell

**Epic:** 3 — Networking + Video Import
**Priority:** Must-have
**Depends on:** STORY-011 (HomeViewModel provides local video URL)

**As a** ClipForge user,
**I want** the imported video to play in the Trim Modal,
**so that** I can see what I'm working with before trimming.

### Implementation Context

**VideoPlayerManager.swift (Services folder):**
- Accepts local file URL, creates `AVURLAsset` and `AVPlayerItem`
- Exposes `AVPlayer` for SwiftUI view
- `player.isMuted = true` by default
- `@Published var isMuted: Bool` bound to volume toggle
- `@Published var duration: Double` (total duration in seconds)
- `@Published var currentTime: Double` (current playback position)
- Renders first frame on load (seek to .zero, then pause)

**TrimModalView (shell):**
- Full-screen modal via `.fullScreenCover` when importState is `.success`
- Background: `Color.black.ignoresSafeArea()`
- Top bar: Volume toggle (Liquid Glass Symbol button, `speaker.wave.2.fill` / `speaker.slash.fill`) top-left. Cancel button (Liquid Glass Text button, "Cancel") top-right
- Center: Video player fills available width, maintains aspect ratio, black letterboxing
- Bottom area: Placeholder for trim bar, duration readout, CREATE button (Epic 4 and 5)
- Video autoplays on modal appearance

### Acceptance Criteria

- [ ] Trim Modal presents as full-screen modal from Home when import succeeds
- [ ] Video plays automatically, muted, on modal open
- [ ] First frame renders before autoplay (no black flash)
- [ ] Video maintains original aspect ratio with black letterboxing
- [ ] Volume toggle switches between muted and unmuted
- [ ] Cancel button dismisses modal and returns to Home
- [ ] Video player fills available width edge-to-edge
- [ ] Background is pure black with no visible padding or margins

---

## Done Criteria for Epic 3

Epic 3 is complete when:
1. All five stories pass their acceptance criteria
2. A user can copy a Twitter/X URL, open ClipForge, tap CREATE GIF, see the progress ring animate, and the Trim Modal opens with the video playing
3. Clipboard detection works for all five supported platforms
4. YouTube URLs show the rejection message
5. Network errors display user-friendly messages (no "download" language)
6. The Trim Modal correctly plays imported video with mute toggle and cancel functionality
