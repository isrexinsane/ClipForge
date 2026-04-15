---
title: "CLAUDE.md — ClipForge Master Context"
project: ClipForge
type: master-context
version: 1.2
date: 2026-04-11
status: active
bmad_phase: "Phase 4 — Validation & Sharding (Complete)"
tags: [clipforge, bmad, ios, gif, master-context]
---

# CLAUDE.md — ClipForge

> **Read this file first.** Every Claude instance working on ClipForge — Chat, Cowork, or Code — reads this document before doing anything else. It is the single source of truth for project state, architecture, constraints, and cross-references.

---

## App Identity

**Name:** ClipForge
**One-liner:** Paste a social media link, get a trimmed GIF in seconds.
**Value proposition:** ClipForge compresses a 3-4 app workflow (copy link → open downloader → save video → open GIF maker → import → trim → export) into a single-app experience (paste link → trim → export GIF) that takes under 30 seconds. Speed is the product — by the time someone finishes the old workflow, the meme moment has passed.

**Founder:** Rex, Ronin Art House
**Development method:** BMAD (Breakthrough Method for Agile AI-Driven Development) with the Claude tool suite
**Platform:** iOS (native Swift/SwiftUI)

---

## Architecture Overview

ClipForge uses a two-tier architecture: a cloud-hosted backend that handles video extraction from social media URLs, and a native iOS client that handles everything the user sees and touches — video playback, trimming, GIF encoding, and export.

The reason for this split is both technical and strategic. Extracting video from social media platforms requires yt-dlp, a Python library that reverse-engineers platform video streams. Apple has historically rejected iOS apps that bundle video-downloading libraries, and yt-dlp requires frequent updates as platforms change their APIs. By keeping yt-dlp on a server, the iOS app stays App Store compliant, and extraction logic can be updated instantly without waiting for App Store review.

### System Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        USER DEVICE                          │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                 ClipForge iOS App                     │  │
│  │                 (Swift / SwiftUI)                     │  │
│  │                                                       │  │
│  │  ┌─────────────┐  ┌──────────────┐  ┌─────────────┐  │  │
│  │  │  Link Paste  │→│ Video Player │→│ GIF Export  │  │  │
│  │  │  + Import    │  │ + Trimmer    │  │ + Save      │  │  │
│  │  └──────┬──────┘  └──────────────┘  └─────────────┘  │  │
│  │         │              ▲                    │          │  │
│  │         │              │                    ▼          │  │
│  │         │         AVFoundation         ImageIO /       │  │
│  │         │         (native trim)        CoreGraphics    │  │
│  │         │                              (GIF encode)    │  │
│  └─────────┼─────────────────────────────────────────────┘  │
│            │                                                 │
└────────────┼─────────────────────────────────────────────────┘
             │ HTTPS POST (URL)
             ▼
┌─────────────────────────────────────────────────────────────┐
│                      CLOUD SERVER                           │
│                   (Railway / Fly.io)                         │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              FastAPI Backend (Python)                  │  │
│  │                                                       │  │
│  │  ┌──────────────┐    ┌─────────────────────────────┐  │  │
│  │  │  /extract    │───→│  yt-dlp (video extraction)  │  │  │
│  │  │  endpoint    │    │  Updated server-side only    │  │  │
│  │  └──────────────┘    └─────────────────────────────┘  │  │
│  │         │                                              │  │
│  │         ▼                                              │  │
│  │  Returns: signed URL to video file                     │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Development Principles (Karpathy Guidelines)

These behavioral guidelines govern all Claude Code sessions on ClipForge. They reduce common LLM coding mistakes: overcomplication, silent assumptions, orthogonal edits, and weak success criteria. Derived from Andrej Karpathy's observations, adapted for this project. Source: `github.com/forrestchang/andrej-karpathy-skills`

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks (simple typo fixes, obvious one-liners), use judgment — not every change needs the full rigor. The goal is reducing costly mistakes on non-trivial work, not slowing down simple tasks.

### 1. Think Before Coding

*Don't assume. Don't hide confusion. Surface tradeoffs.*

Before implementing any story or task:

- State your assumptions explicitly. If uncertain, ask Rex.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.
- Check the Architecture Spec, API Contract, and this CLAUDE.md before making architectural decisions. If your implementation would deviate from these documents, flag it explicitly.

### 2. Simplicity First

*Minimum code that solves the problem. Nothing speculative.*

- No features beyond what the current BMAD story specifies.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

**The test:** Would a senior engineer say this is overcomplicated? If yes, simplify. Rex is a non-developer — every line of code he inherits must be as readable and maintainable as possible.

### 3. Surgical Changes

*Touch only what you must. Clean up only your own mess.*

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code or issues, mention them to Rex — don't silently fix them.

When your changes create orphans:

- Remove imports, variables, and functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless the current story explicitly asks for it.

**The test:** Every changed line should trace directly to the current BMAD story's requirements.

### 4. Goal-Driven Execution

*Define success criteria. Loop until verified.*

Transform tasks into verifiable goals. Each BMAD story has acceptance criteria — use them as your success loop:

| Instead of... | Transform to... |
|---------------|----------------|
| "Add validation" | "Write tests for invalid inputs, then make them pass" |
| "Fix the bug" | "Write a test that reproduces it, then make it pass" |
| "Refactor X" | "Ensure tests pass before and after" |

For multi-step tasks, state a brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let Claude Code loop independently. Weak criteria ("make it work") require constant clarification. The BMAD story acceptance criteria are always the primary success definition.

---

## Tech Stack

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| **iOS Client** | Swift / SwiftUI | Native performance for the video processing pipeline, which is the core product. SwiftUI provides modern declarative UI with Apple's latest design patterns. Path A from feasibility report. |
| **Video Trimming** | AVFoundation (AVAsset, AVPlayerItem, AVAssetExportSession) | Apple's native media framework. Frame-accurate trimming with real-time preview playback. No third-party dependencies. |
| **GIF Encoding** | ImageIO / CoreGraphics (CGImageDestination) | Native iOS framework for creating animated GIFs from extracted video frames. Configurable frame rate and dimensions. No external libraries needed. |
| **GIF Optimization** | On-device palette optimization + lossy compression | Frame rate reduction, color palette optimization, and lossy compression applied locally to hit platform file size limits without additional server calls. |
| **Backend API** | Python 3.12+ / FastAPI | FastAPI provides automatic OpenAPI docs, async support, Pydantic validation, and is the standard for Python web APIs. Lightweight enough for a single-purpose extraction service. |
| **Video Extraction** | yt-dlp (Python library) | The de facto standard for extracting video from social media URLs. Supports 1,700+ platforms. Updated frequently by open-source community. Runs server-side only. |
| **Hosting** | Railway or Fly.io | Low-cost VPS platforms with simple deployment ($5–20/month). Support Python, auto-scaling, and custom domains. Railway has a particularly simple deploy-from-GitHub workflow. |
| **UI Prototyping** | Google Stitch + Figma (with Apple iOS 26 Design Kit) | Stitch generates interactive prototypes from natural language. Figma refines against Apple's official components. Both free. |
| **IDE** | Xcode | Required for Swift/SwiftUI development, simulator testing, and App Store submission. Free on macOS. |
| **Project Framework** | BMAD Method (open-source, npm) | Structures AI-assisted development into a multi-agent pipeline. Provides the project management and technical decomposition layer that a solo non-developer needs. |

---

## API Contract

The iOS client interacts with exactly these endpoints. All communication uses HTTPS with JSON payloads. The full API Contract document (`API_Contract.md`) is the authoritative reference — this section is a working summary that stays in sync with it.

**Video delivery model:** The backend always returns a temporary signed URL (valid 5 minutes) pointing to `/v1/media/{file_id}`. The iOS client fetches the video from that URL. There is no base64-encoded inline delivery mode — all video delivery goes through the signed URL path regardless of file size. This keeps the extraction response lightweight and the client download logic a single code path.

### Base URL and Authentication

```
https://api.clipforge.app/v1
```

During development and TestFlight beta, a staging URL (`https://api-staging.clipforge.app/v1`) is used. The iOS client reads the base URL from a configuration file, making the switch a build-time setting.

Every request (except `/health`) must include an API key header: `X-API-Key: cf_live_xxxx...`. The key authenticates the app, not individual users — there are no user accounts in the MVP.

### Endpoints

---

#### `POST /v1/extract`

The core endpoint. Accepts a social media URL, extracts the video via yt-dlp, and returns a temporary signed URL to retrieve the video file.

**Request:**

```json
{
  "url": "https://x.com/user/status/1234567890",
  "max_resolution": "720p",
  "max_duration": 60
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `url` | string | Yes | The social media URL to extract video from |
| `max_resolution` | string | No | Maximum video resolution: `"480p"` or `"720p"`. Default: `"720p"`. |
| `max_duration` | integer | No | Maximum source video duration in seconds. Default and max: `60`. Returns error if exceeded. |

**Response (success — 200):**

```json
{
  "status": "success",
  "platform": "twitter",
  "video_url": "https://api.clipforge.app/v1/media/tmp_a1b2c3d4.mp4?token=eyJ...&expires=1712800000",
  "duration": 14.2,
  "width": 1280,
  "height": 720,
  "file_size": 4821504,
  "content_type": "video/mp4",
  "title": "Coach reaction after the missed call"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `status` | string | Always `"success"` |
| `platform` | string | Detected platform: `"twitter"`, `"instagram"`, `"reddit"`, `"tiktok"`, `"twitch"` |
| `video_url` | string | Temporary signed URL to retrieve the video. Valid for 5 minutes. Points to `/v1/media/{file_id}`. |
| `duration` | float | Video duration in seconds |
| `width` | integer | Video width in pixels |
| `height` | integer | Video height in pixels |
| `file_size` | integer | Video file size in bytes |
| `content_type` | string | MIME type, typically `"video/mp4"` |
| `title` | string or null | Title/caption of the source post, if available. Reserved for future features. |

**Response (error — 4xx/5xx):**

```json
{
  "status": "error",
  "error_code": "UNSUPPORTED_PLATFORM",
  "message": "The URL host 'youtube.com' is not in the supported platforms list.",
  "retry_after": null
}
```

| Error Code | HTTP Status | Meaning |
|-----------|-------------|---------|
| `UNSUPPORTED_PLATFORM` | 400 | URL host is not in the supported platforms list |
| `INVALID_URL` | 400 | URL is malformed or doesn't match any supported pattern |
| `VIDEO_TOO_LONG` | 400 | Source video exceeds `max_duration` |
| `EXTRACTION_FAILED` | 502 | yt-dlp failed (platform change, private content, deleted post) |
| `EXTRACTION_TIMEOUT` | 504 | yt-dlp did not complete within 30 seconds |
| `PLATFORM_UNAVAILABLE` | 503 | Extractor for this platform is known broken (manually flagged) |
| `RATE_LIMITED` | 429 | Rate limit exceeded; `retry_after` field contains seconds to wait |
| `UNAUTHORIZED` | 401 | Missing or invalid API key |
| `SERVER_ERROR` | 500 | Unhandled server exception |

**Rate limits:** 10/minute, 60/hour, 200/day per API key. Status returned via `X-RateLimit-*` headers on every response.

---

#### `GET /v1/media/{file_id}`

Serves the extracted video file. This is the URL returned in the `video_url` field of the extract response. Authenticated by the signed `token` query parameter (no `X-API-Key` header needed), so `URLSession` can consume it directly.

**Query parameters:** `token` (required), `expires` (required — Unix timestamp).

**Response (success — 200):** Raw video file data, streamed, with `Content-Length` and `Content-Disposition` headers.

| Error Code | HTTP Status | Condition |
|-----------|-------------|-----------|
| `INVALID_TOKEN` | 403 | Token is malformed or signature mismatch |
| `EXPIRED_MEDIA` | 410 | 5-minute window has passed; file cleaned up |
| `MEDIA_NOT_FOUND` | 404 | File ID doesn't exist |

---

#### `GET /v1/health`

Lightweight health check. No authentication required.

**Response (200):**

```json
{
  "status": "healthy",
  "yt_dlp_version": "2026.04.07",
  "supported_platforms": ["twitter", "instagram", "reddit", "tiktok", "twitch"],
  "uptime_seconds": 86412
}
```

---

## Supported Platforms

These platforms are supported in the ClipForge MVP. The list is maintained server-side and included in the `/v1/health` response, allowing updates without an App Store review.

| Platform | yt-dlp Status | MVP Priority | Notes |
|----------|--------------|-------------|-------|
| Twitter / X | Full support | **Primary** | Core use case — reaction clips and meme content |
| Instagram | Full support | High | Reels and story clips. May require login cookies for some content. |
| Reddit | Full support | High | Video posts and v.redd.it links |
| TikTok | Full support | Medium | Useful for cross-posting; TikTok has its own save feature but adds watermarks |
| Twitch | Full support | Medium | Clips and VOD segments |

### Explicitly Excluded from MVP

| Platform | Reason |
|----------|--------|
| **YouTube** | YouTube is the platform most likely to trigger App Store rejection. Apple has a documented pattern of removing apps that facilitate YouTube video extraction. The iOS Seal app (a validated comparable) notably excludes YouTube. ClipForge excludes YouTube from v1.0 to reduce App Store risk. This may be revisited post-launch after establishing a clean review track record with Apple. |

---

## GIF Encoding Parameters

All GIF encoding runs on-device using ImageIO (CGImageDestination). There are no user-facing quality presets — the encoder auto-optimizes every GIF to a single "Works Everywhere" target.

### Works Everywhere Encoding

| Parameter | Range | Behavior |
|-----------|-------|----------|
| **Target file size** | ≤8 MB | Hard ceiling for all output. Clears Discord non-Nitro (10 MB), Twitter/X (15 MB), iMessage, and Messenger (25 MB). |
| **Frame rate** | 10–15 FPS | Encoder selects highest FPS that fits within size budget. Short clips get 15 FPS; longer clips auto-reduce. |
| **Max width** | 480–640px | Encoder selects largest width that fits within size budget. Aspect ratio always preserved. |
| **Color depth** | 256 colors | GIF format maximum. Global palette optimized across all frames. |
| **Max duration** | 15 seconds | Hard cap. Trim handles prevent selecting a range longer than this. |

No user-facing settings screen. No preset selector. No GIF settings step between trim and export. The user trims → taps one button → GIF encodes and exports.

**Rationale:** 8 MB clears every major sharing platform's file size limit without the user needing to know or choose anything. Eliminating presets removes one entire screen from the flow and one decision from the user's path.

### Encoding Pipeline

1. **Frame extraction:** AVAssetImageGenerator extracts frames from the trimmed video at the auto-selected frame rate (10–15 FPS based on trim duration and source resolution).
2. **Resize:** Each frame is scaled to the auto-selected max width (480–640px), maintaining aspect ratio.
3. **Watermark compositing:** ClipForge logomark (PNG asset, ~50 KB) composited bottom-right at 40–50% opacity, approximately 10–15% of frame width. Free tier only; premium users get clean output. MVP uses monospace text treatment until final branding is designed.
4. **Palette optimization:** A global color palette is computed across all frames for better compression and visual consistency (256 color limit for GIF format).
5. **GIF assembly:** CGImageDestination writes frames sequentially with the configured inter-frame delay (1/fps).
6. **Size check:** If the output exceeds the ≤8 MB target, the encoder automatically reduces frame rate or dimensions and re-encodes. The user sees a progress indicator during this step.
7. **Save:** The finished GIF is saved to the Photos library via PHPhotoLibrary.

### Size Optimization Levers (Applied Automatically)

| Lever | Effect | Applied When |
|-------|--------|-------------|
| Frame rate reduction | Fewer frames = smaller file | Output exceeds ≤8 MB target |
| Dimension reduction | Smaller pixels = smaller file | Frame rate reduction alone is insufficient |
| Lossy compression | Reduces color precision per frame | Final pass if still over ≤8 MB target |
| Duration cap | Trims to max 15 seconds | User selects a clip longer than 15s |

---

## App Store Compliance Rules

These rules govern all user-facing content: the app UI, App Store listing, metadata, screenshots, onboarding copy, error messages, and marketing materials.

### Banned Terms (Never Use)

| Banned Term | Approved Alternatives |
|------------|----------------------|
| download | import, capture, create from link, save |
| downloader | creator, maker, converter |
| rip / ripper | extract, capture |
| save video (as a primary feature description) | create GIF from video, capture moments |

### Required Framing

The app must be positioned as a **GIF creation tool**, not a video downloading tool. The video import is an intermediate step in a creative workflow — it is not the product.

Lead all descriptions with GIF creation language:

- App Store subtitle: "Create reaction GIFs from social media moments"
- First line of description: "ClipForge turns your favorite social media moments into perfectly trimmed, shareable GIFs."
- Feature list leads with GIF creation, trimming, and sharing — not video import

### Required Legal Elements

- Privacy policy: Must exist and be linked in the App Store listing. ClipForge collects zero personal data — the privacy policy should state this explicitly.
- Copyright notice in the app (Settings or About screen): "ClipForge is intended for personal, non-commercial use of content you have the right to use."
- DMCA compliance: The backend must support a process for responding to takedown requests (can be a documented manual process for MVP).

### Review Strategy

- Submit to App Store with a clear App Review note explaining the app's purpose as a GIF creation tool.
- Exclude YouTube from the initial submission to avoid triggering automated flags.
- Include a demo video showing the full GIF creation workflow (link paste → trim → GIF export) to demonstrate the creative intent.
- If initially rejected, respond with a detailed explanation of how ClipForge differs from pure downloaders (creative tool, GIF output, editing interface).

---

## Design Decisions Log

Confirmed design decisions that update or override original BMAD artifacts. Each entry includes the date, decision, rationale, and which documents were affected. Decisions should not be revisited without Rex's explicit approval.

| Date | Decision | Rationale | Documents Affected |
|------|----------|-----------|-------------------|
| 2026-04-11 | **GIF Presets → REMOVED.** Three-tier preset system replaced by single "Works Everywhere" auto-encoding (≤8 MB). No user-facing settings screen. | 8 MB clears Discord non-Nitro, Twitter/X, iMessage, and Messenger. Removes one screen and one user decision from the flow. | PRD (F-06 removed), Architecture_Spec (§4.4, §8.2), CLAUDE.md (encoding section, key decisions), Epic_Breakdown (Epic 5), Master_Checklist (F-06 row, Gap #4) |
| 2026-04-11 | **Freemium Model → REVISED.** Free limit changed from 3/day to 1/day. Price changed from $1.99/mo + $9.99/yr to $9.99/yr only. HD preset unlock removed (no presets). | 1/day creates tighter conversion pressure during the app's novelty window. Single price eliminates decision friction. | PRD (F-08, AC-08.x, §8 Monetization), Architecture_Spec (§3.5), CLAUDE.md (key decisions), Epic_Breakdown (Epics 7, 8) |
| 2026-04-11 | **Watermark → LOGOMARK.** Text watermark ("Made with ClipForge") replaced by logomark PNG asset. MVP uses monospace text treatment until final branding. | More professional appearance; asset is swappable without code changes when branding finalizes. | PRD (F-09, AC-09.x), Architecture_Spec (§4.4), Epic_Breakdown (Epic 7) |
| 2026-04-11 | **Trim Modal → iOS Photos Pattern.** Full-screen modal redesigned: black background, edge-to-edge video, iOS Photos-style trim bar with chevron handles, playhead, play button. GIF Settings screen removed from flow. | Matches the native iOS editing pattern users already know. Reduces learning curve to zero for the trim interaction. | PRD (Flows 2-4), Architecture_Spec (§3.2 navigation), Epic_Breakdown (Epic 4) |
| 2026-04-11 | **VideoTrimmerControl flagged.** MIT-licensed Swift UIKit control (github.com/AndreasVerhoeven/VideoTrimmerControl) identified for evaluation during Epic 4. | Replicates iOS Photos trim bar behavior. Could save significant dev time on trim interface — integrate directly or use as architectural reference. | CLAUDE.md (cross-references), Epic_Breakdown (Epic 4) |
| 2026-04-11 | **Navigation Model → CHANGED.** Five-screen NavigationStack replaced by two swipeable pages (Home ↔ Gallery) + full-screen modal sheets for trim/export. | Simpler architecture, matches Seal app pattern. User never "leaves" Home. | PRD (user flows), Architecture_Spec (§3.2), Design_Decisions.md |
| 2026-04-11 | **Light Mode with Vermillion Gradient.** Dark mode default replaced by warm off-white (#F5F0EB) with top-down #EF3340 gradient. | Aligns with Ronin Art House brand identity. Warm, distinctive, not generic dark-mode. | Design System Brief, Design_Decisions.md |
| 2026-04-11 | **Tab Bar → REMOVED.** Three-tab bottom bar replaced by horizontal swipe + CAVA-style animated page dots. | Cleaner UI, fewer elements, swipe is the natural gesture for two-page apps. | PRD (navigation), Architecture_Spec (§3.2), Design_Decisions.md |
| 2026-04-11 | **Home Screen → Single Button.** Text input field removed. Single CTA button with automatic clipboard detection. | Fastest possible interaction — zero typing, zero decisions. | PRD (Flow 1), Design_Decisions.md |
| 2026-04-11 | **Typography → JetBrains Mono + Inter.** SF Pro replaced by dual-font system. JetBrains Mono for display/UI, Inter for body text. | Monospace gives precision-tool identity; humanist gives readability. Both SIL-licensed, screen-optimized. | Design System Brief, Design_Decisions.md |
| 2026-04-12 | **CREATE GIF Button Loading Ring.** Button border becomes progress ring during video import. Indeterminate animation during extraction API call, determinate vermillion stroke during video file download via URLSession. | Users keep eyes on the element they just tapped. Progress ring on the button provides visual anchor during 3–15 second wait. | PRD (Flow 1 step 6), Architecture_Spec (§4.2), Epic_Breakdown (Epic 3) |
| 2026-04-12 | **Encoding Progress → In-Modal State.** Not a separate screen. CREATE button transforms into circular progress ring with percentage (JetBrains Mono Bold, white). Trim bar remains visible above. | No screen transition needed. User stays in same modal context. Spatial continuity maintained. | PRD (Flow 4 step 1), Epic_Breakdown (Epic 5) |
| 2026-04-12 | **Export Success → In-Modal State.** Not a separate screen. Video area shows looping GIF preview. Trim bar disappears. Share (vermillion fill) and Done (white outline) buttons appear. Free tier shows "0 of 1 free GIFs remaining today." | Same modal, same context. User's mental model: "I opened a tool, it did its thing, here's the result, now I close it." | PRD (Flow 4 steps 4-8), Architecture_Spec (§3.2), Epic_Breakdown (Epic 6) |
| 2026-04-12 | **Media Library Tile → iOS Share Sheet.** Tap opens share sheet directly. No in-app detail view. Gallery is visual index only in MVP. | Keep MVP lean. iOS share sheet handles all downstream actions. In-app GIF management deferred to v1.2+. | PRD (F-22 note), Epic_Breakdown (Epic 6) |
| 2026-04-12 | **Menu Button (Home).** Standard iOS context menu with three items: Restore Purchase, Privacy Policy, About ClipForge. No Figma mockup needed. | Standard iOS pattern. No custom design required. | Epic_Breakdown (Epic 1) |
| 2026-04-12 | **Phase 5 Complete.** Figma frames 04/05 are not separate screens — they are state changes within Frame 03 (Trim Modal). Developer receives visual direction through SM story documents, not direct Figma consumption. | Encoding Progress and Export Success are in-modal states, eliminating two screens from the navigation architecture. | CLAUDE.md (Phase Tracker), Supplemental_Handoff_2026-04-12.md |
| 2026-04-12 | **Single error enum.** `ClipForgeError` instead of separate `ClipForgeAPIError`. `isTransient` computed property for retry logic. | Simplicity: one enum covers all app errors with a consistent pattern. | Developer (Epic 3) |
| 2026-04-12 | **Doubles for trim state.** TrimViewModel uses Double (seconds), converts to CMTime only at AVPlayer boundary. | Better testability and simpler state management. | Developer (Epic 4) |
| 2026-04-12 | **Boundary observer for loop.** Uses `addBoundaryTimeObserver` instead of periodic polling for preview loop. | More precise and battery-efficient than timer-based polling. | Developer (Epic 4) |
| 2026-04-12 | **@State lazy init for TrimViewModel.** Created lazily when player reports duration. Not @StateObject (needs runtime values). | TrimViewModel requires videoDuration at init, which isn't available until AVPlayer loads the asset. | Developer (Epic 4) |
| 2026-04-12 | **Closure for GIF cancellation.** `isCancelled: () -> Bool` closure instead of shared Bool flag. | Works cleanly across async boundaries with Task.isCancelled. | Developer (Epic 5) |
| 2026-04-12 | **CGImageSource in-memory GIF preview.** Direct memory decoding avoids disk I/O on success screen. | Faster preview rendering; no temp file cleanup needed. | Developer (Epic 6) |
| 2026-04-12 | **GIFHistoryStore singleton.** UserDefaults-backed, @MainActor, newest-first ordering. | Simplest persistence for MVP. Can migrate to SwiftData post-launch if needed. | Developer (Epic 6) |
| 2026-04-12 | **ImportState extracted to standalone file.** Moved from HomeViewModel.swift to Models/ImportState.swift. | Prevents cascade compilation failures when HomeViewModel has any issue. Discovered during first Xcode build. | Developer (Build Fix) |
| 2026-04-12 | **Inter variable font.** Info.plist updated to reference `Inter-VariableFont_opsz,wght.ttf` instead of static `Inter-Regular.ttf`/`Inter-Medium.ttf`. CFFont.inter() uses `.weight()` modifier. | Rex downloaded variable font version; static files don't exist. Variable font approach is cleaner (one file, all weights). | Developer (Build Fix) |

---

## BMAD Phase Tracker

This section tracks the current state of the BMAD pipeline. Update it after every phase transition or story completion.

### Current Phase

```
PHASE 10 — INTEGRATION & POLISH (SM/Dev/QA)
Status: NOT STARTED — End-to-end flow testing, error handling, polish
```

### Phase History

| Phase | Status | Completed | Key Artifacts |
|-------|--------|-----------|---------------|
| Phase 0: Project Infrastructure | ✅ Complete | 2026-04-10 | CLAUDE.md, Chat config, Cowork config |
| Phase 1: Research & Brief (Analyst) | ✅ Complete | 2026-04-10 | Project Brief |
| Phase 2: Product Requirements (PM) | ✅ Complete | 2026-04-10 | PRD.md |
| Phase 3: Architecture (Architect) | ✅ Complete | 2026-04-10 | Architecture Spec, API Contract |
| Phase 4: Validation & Sharding (PO) | ✅ Complete | 2026-04-10 | Epic Breakdown, Master Checklist, Sprint 1 Stories (8) |
| Phase 5: UI Prototyping (Human + Tools) | ✅ Complete | 2026-04-12 | Figma prototype (3 frames + 2 state placeholders), Screen_Inventory.md. Encoding Progress and Export Success designed as in-modal states per supplemental handoff. |
| Phase 6: Backend Development (SM/Dev/QA) | ✅ Complete | 2026-04-11 | FastAPI server, deployed API, smoke tests passed |
| Phase 7: Video Import Flow (SM/Dev/QA) | ✅ Complete | 2026-04-12 | Epic 3: 5 stories (STORY-009 through STORY-013). APIService, ClipboardMonitor, HomeViewModel, CTA progress ring, VideoPlayerManager + Trim Modal shell. |
| Phase 8: Trim Interface (SM/Dev/QA) | ✅ Complete | 2026-04-12 | Epic 4: 5 stories (STORY-014 through STORY-018). TrimViewModel, FilmstripGenerator, TrimBarView, Duration Readout, CREATE button, font setup. |
| Phase 9: GIF Engine + Export (SM/Dev/QA) | ✅ Complete | 2026-04-12 | Epics 5+6: 5 stories (STORY-019 through STORY-023). GIFEncoder, ExportViewModel, ExportManager (PHPhotoLibrary), export success UI, ShareSheet, Media Library grid. |
| Phase 10: Integration & Polish (SM/Dev/QA) | ⬜ Not Started | — | End-to-end flow, error handling |
| Phase 11: TestFlight Beta (Human) | ⬜ Not Started | — | Beta builds, bug fixes |
| Phase 12: App Store Submission (Human) | ⬜ Not Started | — | Listing, screenshots, submission |

### Next Actions

1. CRITICAL: Resolve EXTRACT-CONFIG — yt-dlp proxy/cookie configuration in Railway to unblock end-to-end testing
2. Stage 3 Mega-Checkpoint — full end-to-end test across all five platforms
3. PO Full Validation — cross-reference PRD F-01 through F-07
4. Stage 4 — Epic 7 (Freemium: 1/day limit + watermark) and Epic 8 (StoreKit 2: $9.99/yr)
5. Stage 5 — Epics 9–11 (Onboarding, polish, App Store submission)

### Completed Stories

| Story | Epic | Description | Status | Date |
|-------|------|-------------|--------|------|
| STORY-001 | Epic 1: iOS App Shell | Xcode project scaffolding and build configuration | ✅ Complete | 2026-04-10 |
| STORY-002 | Epic 1: iOS App Shell | MVVM folder structure and service stubs | ✅ Complete | 2026-04-10 |
| STORY-003 | Epic 1: iOS App Shell | Navigation structure with placeholder screens | ✅ Complete | 2026-04-10 |
| STORY-004 | Epic 2: Backend API | FastAPI project setup and health endpoint | ✅ Complete | 2026-04-11 |
| STORY-005 | Epic 2: Backend API | URL validation and platform detection | ✅ Complete | 2026-04-11 |
| STORY-006 | Epic 2: Backend API | yt-dlp extraction engine with subprocess isolation | ✅ Complete | 2026-04-11 |
| STORY-007 | Epic 2: Backend API | Signed URL media serving and temp file cleanup | ✅ Complete | 2026-04-11 |
| STORY-008 | Epic 2: Backend API | Railway deployment and production configuration | ✅ Complete | 2026-04-11 |
| STORY-009 | Epic 3: Networking + Video Import | APIService — Core Networking Layer | ✅ Complete | 2026-04-12 |
| STORY-010 | Epic 3: Networking + Video Import | ClipboardMonitor — URL Detection | ✅ Complete | 2026-04-12 |
| STORY-011 | Epic 3: Networking + Video Import | HomeViewModel — Import Flow Orchestration | ✅ Complete | 2026-04-12 |
| STORY-012 | Epic 3: Networking + Video Import | HomeView — CTA Button with Progress Ring | ✅ Complete | 2026-04-12 |
| STORY-013 | Epic 3: Networking + Video Import | VideoPlayerManager + Trim Modal Shell | ✅ Complete | 2026-04-12 |
| STORY-014 | Epic 4: Trim Interface | TrimViewModel — Core Trim State Management | ✅ Complete | 2026-04-12 |
| STORY-015 | Epic 4: Trim Interface | Filmstrip Thumbnail Generator | ✅ Complete | 2026-04-12 |
| STORY-016 | Epic 4: Trim Interface | TrimBarView — Timeline Scrubber UI | ✅ Complete | 2026-04-12 |
| STORY-017 | Epic 4: Trim Interface | Duration Readout and Color Warnings | ✅ Complete | 2026-04-12 |
| STORY-018 | Epic 4: Trim Interface | CREATE Button and Next-Step Trigger | ✅ Complete | 2026-04-12 |
| STORY-019 | Epic 5: GIF Encoding Engine | GIFEncoder — Core Encoding Pipeline | ✅ Complete | 2026-04-12 |
| STORY-020 | Epic 5: GIF Encoding Engine | ExportViewModel — Encoding Orchestration and Progress State | ✅ Complete | 2026-04-12 |
| STORY-021 | Epic 6: Camera Roll Export | Camera Roll Save — PHPhotoLibrary Integration | ✅ Complete | 2026-04-12 |
| STORY-022 | Epic 6: Camera Roll Export | Export Success State — GIF Preview, Share, and Done | ✅ Complete | 2026-04-12 |
| STORY-023 | Epic 6: Camera Roll Export | Media Library — GIF History Grid | ✅ Complete | 2026-04-12 |

### Sprint 2 Backlog — Open Items

| Item | Priority | Status | Description |
|------|----------|--------|-------------|
| EXTRACT-CONFIG | CRITICAL | Open | yt-dlp cookie/proxy configuration to resolve datacenter IP blocking on Railway. All five platform extractions return 502. Blocks all end-to-end testing. Fix: configure yt-dlp with residential proxy or session cookies. |
| AUTH-FIX | Low | Open | FastAPI returns 422 for missing API key header; API Contract §4 specifies 401. Minor backend middleware fix. |
| Concurrency Warnings | Low | Open | 7 Swift Sendable warnings in ExportViewModel, TrimViewModel, VideoPlayerManager. Non-blocking. Epic 10 scope. |
| Visual Polish | Medium | Open | UI renders but doesn't match Figma designs (gradients, spacing, colors). Epic 10 scope. |

### QA Audit Log

| Date | Scope | Result | Notes |
|------|-------|--------|-------|
| 2026-04-11 | Sprint 1 Backend Smoke Test | 11/11 PASS | Health, auth, validation all correct. Extractions return proper 502s due to datacenter IP blocking (infrastructure, not code). Full report in project chat history. |

---

## Cross-References to Project Knowledge Files

| File | Purpose | Status |
|------|---------|--------|
| `ClipForge_Feasibility_Report.docx` | Canonical feasibility analysis. Source of truth for all strategic decisions. | ✅ Complete (Chat only) |
| `CLAUDE.md` (this file) | Master project context. First file read by any Claude instance. | ✅ v1.2 |
| `Project_Brief.md` | Market opportunity validation, competitive landscape, user personas, value proposition. Analyst agent output. | ✅ Complete (Chat only) |
| `PRD.md` | Product Requirements Document. Features, user flows, acceptance criteria, MVP scope, non-functional requirements, success metrics. PM agent output. | ✅ Complete |
| `Architecture_Spec.md` | Full architecture specification. System design, MVVM pattern, data flow, performance architecture, security considerations. Architect agent output. | ✅ Complete |
| `API_Contract.md` | Formal contract between iOS client and backend API. Endpoint specs, schemas, error codes, URL patterns, rate limits, signed URL authentication. Architect agent output. | ✅ Complete |
| `Master_Checklist.md` | PO validation of alignment across Brief, PRD, and Architecture Spec. Identifies 4 gaps with resolutions. PO agent output. | ✅ Complete |
| `Epic3_Stories_Approved.md` | 5 approved stories for Epic 3 (Networking + Video Import): STORY-009 through STORY-013. SM agent output. | ✅ Implemented |
| `Epic4_Stories_Approved.md` | 5 approved stories for Epic 4 (Trim Interface): STORY-014 through STORY-018. SM agent output. | ✅ Implemented |
| `Epic5_6_Stories_Approved.md` | 5 approved stories for Epic 5 (GIF Engine) + Epic 6 (Camera Roll Export): STORY-019 through STORY-023. SM agent output. | ✅ Implemented |
| `Epic_Breakdown.md` | 11 development epics in implementation sequence with scope, dependencies, complexity, and acceptance criteria. PO agent output. | ✅ Complete |
| `03 — Design/Design System.md` | Design system brief: color palette (Ronin Art House brand), typography (JetBrains Mono + Inter), spacing, component inventory. PM agent output. | ✅ Complete |
| `03 — Design/Design_Decisions.md` | Session handoff artifact: all design decisions, Figma state, deployment details, next steps. | ✅ Complete |
| `03 — Design/Session_Handoff_2026-04-11_v2.md` | Session handoff v2: preset removal, freemium revision, trim modal redesign, watermark change. Supersedes v1. | ✅ Complete |
| `VideoTrimmerControl` | MIT-licensed Swift UIKit trim control (github.com/AndreasVerhoeven/VideoTrimmerControl). Evaluate for Epic 4 integration or architectural reference. | 🔍 Flagged for Dev Phase |
| `Screen_Inventory.md` | Maps every Figma frame, in-modal state, and non-screen UI to implementing epics, visual specs, interaction behavior, and component-level story breakdown. PM agent output. | ✅ Complete |
| `03 — Design/Supplemental_Handoff_2026-04-12.md` | Supplemental handoff: 6 final design decisions wrapping up Phase 5. CREATE GIF loading ring, in-modal encoding/export states, media library interaction, menu button, Phase 5 closure. | ✅ Complete |
| `APP_STORE_STRATEGY.md` | Operational compliance playbook. Banned terms, required language, review tactics, listing copy templates. | ✅ Complete |
| `BMAD_LOG.md` | Running log of agent decisions, approvals, and phase transitions. Reverse chronological. | ✅ Active |
| `Master_Session_Handoff_2026-04-12.md` | Supersedes all previous handoff documents. Complete project state as of first Xcode build. Covers Phase 5 completion through Epics 3–6, build fixes, simulator results. | ✅ Complete |
| Karpathy Guidelines (integrated) | Behavioral coding principles for Claude Code sessions. Prevents overcomplication, silent assumptions, orthogonal edits. Source: `github.com/forrestchang/andrej-karpathy-skills` | ✅ Integrated into CLAUDE.md |

---

## Quick Reference: Key Decisions

These decisions have been made and documented. They should not be revisited without Rex's explicit approval.

| Decision | Choice | Rationale | Source |
|----------|--------|-----------|--------|
| iOS framework | Swift/SwiftUI (Path A) | Native performance for video pipeline; core product quality | Feasibility Report §5.2 |
| Backend framework | Python 3.12+ / FastAPI | Standard for Python APIs; Pydantic validation; async support | Feasibility Report §3.1 |
| Video extraction | Server-side yt-dlp only | App Store compliance; instant update capability | Feasibility Report §3.2 |
| YouTube support | Excluded from MVP | Highest App Store rejection risk | Feasibility Report §3.3, §6.1 |
| GIF encoding | ImageIO/CoreGraphics on-device | Native, no dependencies, no server cost for encoding | Feasibility Report §3.4 |
| GIF presets | Single auto-optimized output (≤8 MB, "Works Everywhere") | Eliminates user decision; covers all major sharing platforms | Session Handoff v2 §1.1 |
| Video delivery | Signed URL via /v1/media/{file_id} (always) | Single code path on iOS client; no base64 inline mode | API Contract §3.2, Architecture Spec §4.2 |
| Hosting | Railway or Fly.io | Low cost ($5–20/mo), simple deployment, Python support | Feasibility Report §5.1 |
| Dev methodology | BMAD Method | Structured agent pipeline for non-developer founder | Feasibility Report §4 |
| Monetization | Freemium (1/day free, $9.99/yr unlimited + no watermark) | Tighter conversion funnel; single price eliminates decision friction | Session Handoff v2 §1.2 |
| UI design tools | Google Stitch → Figma | Stitch couldn't achieve iOS 26 Liquid Glass; Figma with Apple design kit is primary | Feasibility Report §5.3, Design_Decisions §1.3 |
| Navigation model | Two pages (Home ↔ Gallery) + full-screen modal sheets | Replaces original five-screen NavigationStack. Simpler, matches Seal pattern. | Design_Decisions §2.1 |
| Color mode | Light mode with vermillion gradient (not dark mode) | Warm off-white (#F5F0EB) background with top-down #EF3340 gradient | Design_Decisions §2.3 |
| Typography | JetBrains Mono (display/UI) + Inter (body) | Dual-font system: monospace for precision identity, humanist for readability | Design_Decisions §3.5, Design System Brief |
| Tab bar | Removed — swipe navigation with CAVA-style page dots | Horizontal swipe between Home and Gallery, animated dot indicator | Design_Decisions §2.4 |
| User accounts | None — StoreKit 2 binds to iCloud account | Zero data collection, no login UI | Design_Decisions §2.7 |
| Home screen | Single CTA button with auto clipboard detection | No text field, no paste UI — button state changes when supported URL detected | Design_Decisions §2.2 |
