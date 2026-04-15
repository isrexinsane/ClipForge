---
title: "ClipForge — Architecture Specification"
agent: Architect
phase: Planning
status: Complete
date: 2026-04-10
project: ClipForge
org: Ronin Art House
depends_on:
  - Project_Brief.md
  - PRD.md
---

# ClipForge — Architecture Specification

## 1. System Architecture Overview

ClipForge is a two-tier system: a cloud-hosted backend responsible for video extraction from social media URLs, and a native iOS client responsible for video playback, trimming, GIF encoding, and export. The boundary between these tiers is intentional and driven by App Store compliance — the iOS binary must contain zero video extraction logic. All extraction runs server-side via yt-dlp, which can be updated instantly without App Store review cycles.

The tiers communicate over HTTPS through a RESTful JSON API. The iOS client is the only consumer of this API. There is no web frontend, no admin dashboard, and no third-party API access in the MVP.

### 1.1 System Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER DEVICE (iOS)                        │
│                                                                 │
│  ┌──────────┐    ┌──────────────┐    ┌───────────────────────┐  │
│  │ Clipboard │───▶│  SwiftUI     │───▶│  AVFoundation         │  │
│  │ Detection │    │  View Layer  │    │  Video Player + Trim  │  │
│  └──────────┘    └──────┬───────┘    └───────────┬───────────┘  │
│                         │                        │              │
│                         │                        ▼              │
│                  ┌──────▼───────┐    ┌───────────────────────┐  │
│                  │  Networking  │    │  ImageIO / CoreGraphics│  │
│                  │  Layer       │    │  GIF Encoding Engine   │  │
│                  │  (URLSession)│    └───────────┬───────────┘  │
│                  └──────┬───────┘                │              │
│                         │                        ▼              │
│                         │               ┌────────────────────┐  │
│                         │               │  PHPhotoLibrary    │  │
│                         │               │  Camera Roll Export│  │
│                         │               └────────────────────┘  │
└─────────────────────────┼───────────────────────────────────────┘
                          │ HTTPS (TLS 1.3)
                          │ JSON API
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                     CLOUD BACKEND (VPS)                         │
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────┐  │
│  │  FastAPI      │───▶│  yt-dlp      │───▶│  Temporary File  │  │
│  │  Application  │    │  Extraction  │    │  Storage (/tmp)  │  │
│  │  Server       │◀───│  Engine      │◀───│  (auto-cleanup)  │  │
│  └──────┬───────┘    └──────────────┘    └──────────────────┘  │
│         │                                                       │
│  ┌──────▼───────┐    ┌──────────────┐                          │
│  │  Rate Limiter │    │  URL         │                          │
│  │  (in-memory)  │    │  Validator   │                          │
│  └──────────────┘    └──────────────┘                          │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 Tier Responsibilities

The backend has a single job: accept a social media URL, extract the video, and return it. It performs URL validation, platform identification, yt-dlp invocation, and temporary file management. It does not store user data, track sessions, or manage subscriptions.

The iOS client handles everything else: clipboard detection, the entire UI layer (onboarding, import prompt, video player, trim interface, GIF settings, export confirmation), video trimming via AVFoundation, GIF encoding via ImageIO/CoreGraphics, freemium gating via local storage, subscription management via StoreKit 2, and camera roll export via PHPhotoLibrary.

This split means the backend is stateless and lightweight. It does not need a database. It does not need user authentication in the traditional sense — the iOS app authenticates with a static API key, not user credentials.

## 2. Backend Design

### 2.1 Technology Stack

The backend runs Python 3.12+ with FastAPI as the web framework. FastAPI was chosen over Flask for its built-in async support (critical for handling concurrent extraction requests without blocking), automatic OpenAPI documentation generation, and Pydantic-based request/response validation that catches malformed input before it reaches yt-dlp.

| Component | Technology | Version | Rationale |
|-----------|-----------|---------|-----------|
| Runtime | Python | 3.12+ | yt-dlp is Python-native; eliminates FFI complexity |
| Web framework | FastAPI | 0.115+ | Async-first, Pydantic validation, auto-generated docs |
| ASGI server | Uvicorn | 0.30+ | Production-grade async server for FastAPI |
| Video extraction | yt-dlp | Latest (pinned weekly) | 1,700+ platform extractors; active maintenance community |
| Rate limiting | slowapi | 0.1.9+ | FastAPI-compatible rate limiting middleware |
| Process management | subprocess (stdlib) | N/A | yt-dlp invoked as subprocess for isolation and timeout control |

### 2.2 Deployment Architecture

For the MVP, the backend deploys to a single VPS instance on Railway or Fly.io. Both platforms offer simple container-based deployment from a Git repository, automatic HTTPS, and pay-for-usage pricing starting at $5/month.

The deployment unit is a Docker container built from a minimal Python base image. The Dockerfile installs Python, yt-dlp, and ffmpeg (a yt-dlp dependency for certain extractors that need post-processing). The container exposes a single HTTP port that Uvicorn listens on.

**Why not serverless (AWS Lambda / Google Cloud Functions)?** Video extraction can take 5–15 seconds depending on the platform and video length. Serverless functions have cold-start latency (adding 2–5 seconds) and execution time limits that create a poor fit. A persistent VPS eliminates cold starts and provides consistent performance. If ClipForge scales beyond a single VPS, the stateless architecture allows horizontal scaling by adding instances behind a load balancer — but this is a post-MVP concern.

**yt-dlp update strategy:** yt-dlp is pinned to a specific version in the requirements file. When a platform change breaks an extractor, the update process is: (1) pull the latest yt-dlp release, (2) test against the affected platform, (3) update the pinned version, (4) push to the deployment branch. Railway and Fly.io auto-deploy on push. Total time from extractor fix to production: under 10 minutes. No App Store review required.

### 2.3 Temporary File Management

When yt-dlp extracts a video, it writes the file to a temporary directory on the server. The backend streams this file back to the iOS client, then deletes it. A cleanup cron job runs every 15 minutes to remove any orphaned files older than 10 minutes, preventing disk space accumulation from failed or abandoned requests.

The server never retains video content beyond the duration of a single request-response cycle. This is important for both storage cost (VPS disk is limited) and legal posture (ClipForge does not host or store user content).

### 2.4 Scaling Considerations

At MVP launch, a single VPS instance with 1 vCPU and 1 GB RAM can handle approximately 10–20 concurrent extraction requests. yt-dlp's resource consumption is modest per-request (it is primarily network-bound, not CPU-bound), but each request holds a file descriptor and temporary disk space.

If the app reaches a scale where concurrent requests exceed the single-instance capacity, the scaling path is straightforward: deploy multiple container instances behind the platform's built-in load balancer (both Railway and Fly.io support this natively). Because the backend is stateless — no database, no sessions, no shared state — any instance can handle any request.

**Cost scaling model:** At $5–20/month for the VPS, the backend cost is negligible relative to even modest subscription revenue. A 5% conversion rate on 10,000 downloads at $9.99/year produces ~$3,500 net annual revenue (after Apple's 30% cut), which comfortably funds backend hosting into five-figure download territory.

## 3. iOS Client Architecture

### 3.1 Framework and Language

The iOS client is built in Swift 5.10+ with SwiftUI for the view layer. This is Path A from the feasibility report, chosen for native performance in the video and GIF pipeline, full access to AVFoundation and ImageIO, and the most natural iOS feel.

The project targets iOS 17.0 as the minimum deployment target (per PRD §6.2), which provides access to current SwiftUI features, StoreKit 2, the PHPhotoLibrary API, and the UIPasteboard clipboard access patterns introduced in iOS 16+.

### 3.2 Application Architecture Pattern

The app follows the MVVM (Model-View-ViewModel) pattern, which maps cleanly to SwiftUI's data-driven rendering model. Each screen has a corresponding ViewModel that owns the business logic and publishes state changes to the View via `@Published` properties and Combine (or async/await observation).

```
┌─────────────────────────────────────────────┐
│                  Views (SwiftUI)             │
│                                             │
│  HomeView ─── ImportPromptView              │
│  PlayerView ─── TrimView                    │
│  GalleryView                                 │
│  OnboardingView ─── SubscriptionView        │
└──────────────┬──────────────────────────────┘
               │ observes @Published state
┌──────────────▼──────────────────────────────┐
│              ViewModels                      │
│                                             │
│  HomeViewModel (clipboard, navigation)      │
│  ImportViewModel (API calls, loading state) │
│  TrimViewModel (handle positions, duration) │
│  ExportViewModel (encoding, progress, save) │  ← drives in-modal states within TrimView
│  SubscriptionViewModel (StoreKit 2 state)   │
└──────────────┬──────────────────────────────┘
               │ calls into
┌──────────────▼──────────────────────────────┐
│              Services / Managers             │
│                                             │
│  APIService (URLSession, backend comms)     │
│  VideoPlayerManager (AVFoundation wrapper)  │
│  GIFEncoder (ImageIO/CoreGraphics pipeline) │
│  ExportManager (PHPhotoLibrary save)        │
│  SubscriptionManager (StoreKit 2 wrapper)   │
│  FreemiumGatekeeper (daily counter, UserDefaults) │
│  ClipboardMonitor (UIPasteboard watcher)    │
└─────────────────────────────────────────────┘
```

### 3.3 Key iOS Frameworks

| Framework | Purpose in ClipForge |
|-----------|---------------------|
| SwiftUI | Entire view layer: all screens, navigation, animations, layout |
| AVFoundation | Video playback (AVPlayer, AVPlayerItem), frame-accurate seeking, trim range management (CMTimeRange), video asset loading (AVURLAsset) |
| ImageIO | GIF encoding via CGImageDestination. Creates animated GIF files frame-by-frame with configurable frame delay, loop count, and color palette |
| CoreGraphics | Frame extraction from AVAssetImageGenerator, image scaling/resizing for auto-optimized encoding, logomark watermark compositing on free-tier GIFs |
| Photos (PhotosUI) | PHPhotoLibrary for saving GIFs to the camera roll, permission management |
| StoreKit 2 | Subscription management: product listing, purchase flow, transaction verification, restore purchases |
| Foundation | URLSession for backend API communication, UIPasteboard for clipboard detection, UserDefaults for local state (daily counter, onboarding completion) |

### 3.4 Navigation Architecture

The app uses a two-page swipeable layout (Home ↔ Gallery) with full-screen modal sheets for the trim/export workflow. There are no tabs, no NavigationStack push for the main flow. The user swipes between Home and Gallery; tapping the CTA on Home presents the trim modal as a .fullScreenCover. The flow within the modal is: Player/Trim → Encoding Progress → Export Success. Dismissing the modal returns to Home. CAVA-style animated page dots serve as the navigation affordance between pages.

The only navigation branches are: (1) the onboarding flow, which appears once on first launch and then never again, and (2) the subscription screen, which can be reached from the freemium gate on the export screen or from the settings screen.

### 3.5 Local State Management

ClipForge stores minimal local state in UserDefaults, because it has no user accounts and no cloud sync. The following keys are persisted:

| Key | Type | Purpose |
|-----|------|---------|
| `hasCompletedOnboarding` | Bool | Prevent onboarding from showing after first completion |
| `dailyExportCount` | Int | Number of GIFs exported today (free tier limit: 1/day) |
| `dailyExportDate` | String (ISO date) | The calendar date the counter applies to; resets at midnight |

No `selectedPreset` key — quality presets have been removed. The encoder uses a single auto-optimized ≤8 MB target.

No personal data, no identifiers, no analytics tokens. This supports the zero-data-collection commitment in the PRD (F-12, AC-12.1).

## 4. Data Flow

This section traces the complete pipeline from "user copies a link" to "GIF saved to camera roll," identifying every system boundary crossing and transformation.

### 4.1 Phase 1: Clipboard Detection and Import Trigger

1. User copies a social media URL in another app (e.g., Twitter/X).
2. User switches to ClipForge (app launch or foreground return).
3. `ClipboardMonitor` reads `UIPasteboard.general.string`. On iOS 16+, this triggers the system paste disclosure banner — the user must approve the paste.
4. `ClipboardMonitor` runs the URL against a regex pattern set for supported platforms (Twitter/X, Instagram, Reddit, TikTok, Twitch). The pattern set is defined in a `SupportedPlatforms` configuration object, not hardcoded in the monitor.
5. If a supported URL is matched, `HomeViewModel` publishes a state change that causes `ImportPromptView` to appear with the platform name and a truncated URL preview.
6. If no match, the home screen shows the manual paste field.

**Boundary crossing:** None. This phase is entirely on-device.

### 4.2 Phase 2: Video Extraction (Client ↔ Server)

1. User taps "Import" (or pastes a URL manually and taps the import button).
2. `ImportViewModel` passes the URL string to `APIService`.
3. `APIService` constructs an HTTPS POST request to `POST /v1/extract` with the URL in the JSON body and the API key in the `X-API-Key` header.
4. The request crosses the network boundary to the backend.
5. FastAPI receives the request. The rate limiter checks the API key against the per-key request budget. The URL validator confirms the URL matches a supported platform pattern.
6. FastAPI invokes yt-dlp as a subprocess with the URL, requesting the best available MP4 stream (no higher than 720p to control file size and transfer time). A 30-second timeout is set on the subprocess.
7. yt-dlp extracts the video and writes it to `/tmp/clipforge/{request_id}.mp4`.
8. FastAPI constructs the JSON response with video metadata and returns a temporary signed URL pointing to the file on the server.
9. The response crosses the network boundary back to the iOS client.
10. `APIService` decodes the response and begins downloading the video from the signed URL to a temporary file in the app's `Caches` directory. The download progress from URLSession drives the CREATE GIF button's progress ring animation on the Home screen — the vermillion stroke animates clockwise proportional to bytes received / total bytes.
11. `ImportViewModel` publishes the local file URL, triggering navigation to the player/trim screen.

**UI note:** During steps 3–9 (extraction API call), the CREATE GIF button shows an indeterminate progress animation since the server does not stream yt-dlp progress. During step 10 (video file download), the button shows determinate progress via URLSession's `Progress` observation.

**Boundary crossings:** (1) iOS client → backend API (HTTPS POST), (2) backend → yt-dlp subprocess, (3) backend → iOS client (HTTPS response or signed URL download).

**Critical performance note:** This phase is the primary latency bottleneck. The PRD requires link-to-player time ≤15 seconds on LTE. The two main contributors are yt-dlp extraction time (typically 2–8 seconds depending on platform) and video data transfer (depends on file size and connection speed). Capping extraction at 720p and ≤30-second source duration keeps the transferred file size under 15 MB in most cases, which is feasible within the 15-second budget on LTE (~10 Mbps typical download speed).

### 4.3 Phase 3: Trim (On-Device)

1. `VideoPlayerManager` loads the cached video file as an `AVURLAsset` and creates an `AVPlayerItem` for playback.
2. `TrimViewModel` initializes the trim range to the full video duration. It exposes `startTime` and `endTime` as published properties bound to the trim handle positions in the UI.
3. As the user drags a trim handle, the ViewModel updates the corresponding time value and calls `AVPlayer.seek(to:toleranceBefore:toleranceAfter:)` with zero tolerance for frame-accurate seeking. The player view updates in real time.
4. The duration indicator is a computed property: `endTime - startTime`, formatted to one decimal place. Color thresholds (orange >10s, red >15s) are evaluated reactively.
5. "Preview Loop" sets the player's `actionAtItemEnd` to replay from `startTime`, creating a seamless loop of the trimmed segment.
6. "Next" triggers GIF encoding directly (no GIF settings screen — presets have been removed), passing the `AVURLAsset` reference and the `CMTimeRange` representing the trim selection.

**Boundary crossing:** None. This phase is entirely on-device using AVFoundation.

### 4.4 Phase 4: GIF Encoding (On-Device)

1. `ExportViewModel` receives the asset and the trim time range.
2. The `GIFEncoder` service calculates encoding parameters targeting ≤8 MB output. It auto-selects frame rate (10–15 FPS) and dimensions (480–640px max width) based on trim duration and source resolution. No user-facing preset selection.
3. `GIFEncoder` creates an `AVAssetImageGenerator` configured for the asset and the trim range. It generates an array of `CGImage` frames at the target frame rate by requesting images at evenly spaced timestamps within the range.
4. If the free tier is active, the `WatermarkCompositor` composites the ClipForge logomark (PNG asset, ~50 KB) onto each `CGImage` using CoreGraphics, positioned bottom-right at 40–50% opacity, approximately 10–15% of frame width. Premium users get clean output. MVP uses monospace text treatment until final branding is designed.
5. `GIFEncoder` creates a `CGImageDestination` with type `kUTTypeGIF` and the frame count. It sets the global GIF properties (loop count = 0, meaning infinite loop). For each frame, it sets the per-frame delay (`kCGImagePropertyGIFDelayTime`) based on the target frame rate and appends the `CGImage`.
6. `CGImageDestination` finalizes the GIF data.
7. `GIFEncoder` checks the output file size against the ≤8 MB target. If oversized, it runs a second pass at reduced dimensions or frame rate. If still oversized after the second pass, it proceeds with a warning message (per PRD Flow 4, step 8).
8. `GIFEncoder` publishes encoding progress as a percentage (frame count processed / total frames) at each frame, driving the progress indicator UI.
9. The finished GIF `Data` object is passed to `ExportManager`.

**Boundary crossing:** None. Entirely on-device.

### 4.5 Phase 5: Camera Roll Export (On-Device)

1. `ExportManager` checks Photos library authorization status via `PHPhotoLibrary.authorizationStatus(for: .addOnly)`.
2. If not yet determined, it requests permission. The system presents the standard iOS permission dialog.
3. If authorized, `ExportManager` performs a `PHPhotoLibrary.shared().performChanges` block that creates a `PHAssetCreationRequest` and adds the GIF data via `addResource(with: .photo, data: gifData, options: nil)`.
4. On success, `ExportViewModel` publishes the success state as an in-modal state change within TrimView (no separate ExportView or navigation transition): the GIF preview replaces the video area and plays in a loop, the trim bar disappears, file size and dimensions are displayed, and the "Share" (vermillion fill) and "Done" (white outline) buttons appear below.
5. The "Share" action creates a `UIActivityViewController` (wrapped for SwiftUI) with the GIF `Data` pre-loaded.
6. On the free tier, `FreemiumGatekeeper` increments the daily counter in UserDefaults and publishes the remaining count.

**Boundary crossing:** iOS app → Photos framework (system-level sandbox crossing, mediated by the permission prompt).

## 5. API Design

The full endpoint specifications, schemas, and examples are in the companion document `API_Contract.md`. This section covers the design philosophy and architectural decisions behind the API.

### 5.1 Design Principles

The API is deliberately minimal. It has two endpoints: one for video extraction and one for health checks. There is no user management, no session state, no content storage, and no CRUD operations. The backend is a pure function: URL in, video out.

All communication is synchronous request-response over HTTPS. The extraction endpoint blocks until yt-dlp completes (or times out). An async/polling model (submit job → poll for result) was considered and rejected for the MVP because it adds complexity on both sides (the server needs job storage; the client needs polling logic) and the typical extraction time (3–10 seconds) is short enough for a synchronous request with a loading indicator. If extraction times increase beyond 15 seconds for certain platforms, the async model can be introduced in a v1.1 API version without breaking existing clients.

### 5.2 Authentication

The API uses a static API key passed in the `X-API-Key` request header. This key is embedded in the iOS app binary. This is not a high-security authentication mechanism — anyone who decompiles the app can extract the key. For the MVP, this is an acceptable trade-off. The API key's purpose is to prevent casual abuse (random bots hitting the endpoint), not to withstand a determined attacker.

If abuse becomes a problem post-launch, the mitigation path is to implement device attestation via Apple's DeviceCheck or App Attest frameworks, which cryptographically prove that a request originates from a legitimate copy of the app running on a real Apple device. This is a post-MVP enhancement.

### 5.3 Rate Limiting

The API enforces rate limits per API key to prevent abuse and control server costs. The MVP limits are generous relative to expected usage:

| Limit | Value | Rationale |
|-------|-------|-----------|
| Per-minute | 10 requests | No user needs more than 10 extractions per minute |
| Per-hour | 60 requests | Sustained heavy use ceiling |
| Per-day | 200 requests | Absolute daily cap; well above free-tier (1/day) and likely premium usage |

Rate limit responses return HTTP 429 with a `Retry-After` header. The iOS client handles this gracefully with a user-facing message: "You're creating GIFs faster than we can keep up! Try again in a moment."

### 5.4 Error Handling Strategy

The API uses a consistent error response schema across all endpoints. Every error includes a machine-readable `error_code` (for client-side logic) and a human-readable `message` (for debugging, not for direct display to users). The iOS client maps `error_code` values to user-facing strings defined in `Localizable.strings`, ensuring error messages are consistent, localized, and never expose technical details.

Defined error codes and their iOS-side messages are specified in `API_Contract.md §4`.

## 6. Framework and Dependency Inventory

### 6.1 Backend Dependencies

| Package | Version | Purpose | License |
|---------|---------|---------|---------|
| Python | 3.12+ | Runtime | PSF |
| FastAPI | 0.115+ | Web framework | MIT |
| uvicorn | 0.30+ | ASGI server | BSD |
| yt-dlp | Latest (pinned) | Video extraction | Unlicense |
| slowapi | 0.1.9+ | Rate limiting | MIT |
| pydantic | 2.x (FastAPI dep) | Request/response validation | MIT |
| ffmpeg | System package | yt-dlp dependency for post-processing | LGPL 2.1 |

**No database driver, no ORM, no caching library.** The backend is intentionally dependency-light.

### 6.2 iOS Dependencies

ClipForge uses zero third-party iOS libraries in the MVP. Every capability is provided by Apple's native frameworks. This is a deliberate choice for three reasons: (1) fewer dependencies means fewer points of failure and fewer supply-chain security risks, (2) native frameworks receive first-class support and documentation from Apple, and (3) App Store review is smoother when the app relies on standard system frameworks.

| Framework | Source | Purpose |
|-----------|--------|---------|
| SwiftUI | Apple (system) | View layer |
| AVFoundation | Apple (system) | Video playback, seeking, trim range |
| ImageIO | Apple (system) | GIF encoding (CGImageDestination) |
| CoreGraphics | Apple (system) | Frame extraction, scaling, watermark compositing |
| Photos | Apple (system) | Camera roll export |
| StoreKit 2 | Apple (system) | In-app subscriptions |
| Foundation | Apple (system) | Networking (URLSession), clipboard, UserDefaults |

If post-launch features (e.g., text overlay, advanced filters) require capabilities beyond these frameworks, third-party libraries will be evaluated at that time.

### 6.3 Development Tools

| Tool | Purpose |
|------|---------|
| Xcode 16+ | Build, run, test, archive, submit to App Store |
| Swift Package Manager | Dependency management (if any third-party packages are added post-MVP) |
| Docker | Backend containerization for deployment |
| Git + GitHub | Version control, CI/CD trigger for backend deployment |

## 7. Security Considerations

### 7.1 API Key Management

The API key is embedded in the iOS binary. On the backend, it is stored as an environment variable, never committed to the Git repository. The Dockerfile reads it from the deployment platform's secrets management (Railway and Fly.io both support encrypted environment variables).

For the iOS client, the key is stored in a configuration file excluded from source control and injected at build time. Even though the key can theoretically be extracted from the binary, the combination of rate limiting and input validation makes abuse costly and low-reward (the API returns video data that is freely available on the source platforms anyway).

### 7.2 Input Validation

The backend validates every incoming URL before passing it to yt-dlp:

1. The URL must be a valid URL (scheme, host, path).
2. The host must match the allowlist of supported platforms (twitter.com, x.com, instagram.com, reddit.com, v.redd.it, tiktok.com, vm.tiktok.com, twitch.tv, clips.twitch.tv). No other domains are accepted.
3. The URL path must match expected patterns for video content on each platform (e.g., Twitter/X status URLs, Instagram reel/p URLs). This prevents yt-dlp from being used as a general-purpose content fetcher.
4. The URL is sanitized to remove query parameters that are not relevant to video extraction (tracking parameters, referral codes).

This validation runs before yt-dlp is invoked, so malformed or malicious URLs never reach the extraction engine.

### 7.3 Subprocess Isolation

yt-dlp runs as a subprocess with a 30-second timeout. If it hangs or enters an infinite loop (which can happen with malformed URLs on certain platforms), the subprocess is killed and the API returns a timeout error. The subprocess has no access to the FastAPI application's memory or state.

### 7.4 Transport Security

All client-server communication uses HTTPS with TLS 1.3. The VPS deployment platforms (Railway, Fly.io) provide TLS termination and certificate management automatically. The iOS client enforces App Transport Security (ATS), which is enabled by default and requires HTTPS for all network connections.

### 7.5 On-Device Security

The iOS client does not store any sensitive data. The API key is the only secret, and it is a shared key (not per-user), so its exposure does not compromise individual user data. Temporary video files in the app's `Caches` directory are cleaned up after GIF encoding completes. The GIF is persisted only in the Photos library, which is managed by iOS's sandbox and permission system.

## 8. Performance Architecture

### 8.1 Identified Bottlenecks

| Bottleneck | Location | Severity | Mitigation |
|------------|----------|----------|------------|
| yt-dlp extraction time | Backend | High | Cap at 720p; 30s source duration limit; timeout at 30s |
| Video data transfer | Network | High | 720p cap keeps files ≤15 MB; backend in region close to user base |
| GIF frame extraction | iOS client | Moderate | AVAssetImageGenerator is hardware-accelerated; parallelizable |
| GIF encoding (ImageIO) | iOS client | Moderate | Preset-driven parameters limit frame count and dimensions |
| Memory during encoding | iOS client | Moderate | Process frames in batches; release each CGImage after encoding |

### 8.2 Performance Targets (from PRD §6.1)

| Metric | Target | Architecture Support |
|--------|--------|---------------------|
| Link-to-player ≤15s | 720p cap, regional VPS, synchronous API | Backend + network |
| Trim handle ≤100ms latency | AVPlayer.seek with zero tolerance; SwiftUI on main thread | iOS client |
| 3s GIF encode ≤5s | ImageIO hardware path, 10-15 FPS auto-selected, 480-640px scaling | iOS client |
| 10s GIF encode ≤20s | Batch frame processing, progressive progress reporting | iOS client |
| Cold launch ≤2s | Minimal app init; no network calls before home screen renders | iOS client |
| Memory ≤300 MB peak | Frame batch processing (not all frames in memory simultaneously) | iOS client |

### 8.3 Memory Management Strategy

GIF encoding is the most memory-intensive operation. A 10-second clip at 15 FPS and 640px produces 150 frames, each approximately 1.5 MB as a raw `CGImage` (640×360 × 4 bytes per pixel). Loading all 150 frames simultaneously would consume ~225 MB, approaching the 300 MB budget and risking an OS-level memory termination.

The mitigation is batch processing. The `GIFEncoder` processes frames in batches of 20. For each batch, it extracts 20 frames from the `AVAssetImageGenerator`, appends them to the `CGImageDestination`, and releases them before extracting the next batch. Peak memory is approximately 20 frames × 1.5 MB = ~30 MB of frame data, plus overhead for the growing GIF data buffer, comfortably within the 300 MB budget.

### 8.4 Network Resilience

The iOS client implements retry logic for transient network failures on the extraction API call. The strategy is: retry up to 2 times with exponential backoff (2-second initial delay, 4-second second delay). After 3 total attempts, the app shows the persistent error message. This handles temporary network drops without overwhelming the backend with retry storms.

The backend does not retry yt-dlp internally. If extraction fails, it fails fast and returns the error. The iOS client decides whether to retry.
