# Epic 3 — Video Import Flow

**Status:** ⬜ Not Started

## Scope

Implement the first user-facing feature: Link → Video playback.

- Read clipboard for supported social media URLs
- Call `POST /v1/extract` with URL validation
- Download video from signed URL returned by backend
- Load video into AVPlayer for preview
- Display video metadata (duration, dimensions, file size)
- Error handling for invalid URLs, extraction failures, network issues

## Design Reference

HomeView → User taps button → Clipboard detected → API call → Video loads in modal → Swipe to Trim

## Dependencies

- ✅ [[Epic 1 — iOS App Shell]] (complete) — navigation structure ready
- ✅ [[Epic 2 — Backend API]] (complete) — extraction API live
- ⏳ [[Blockers#EXTRACT-CONFIG]] (HIGH) — must be resolved before end-to-end testing

## Implementation Details

**Services to flesh out:**
- `APIClient.extract(url:)` — POST request, token management, error mapping
- `VideoService.download(from:)` — URLSession streaming, progress callbacks
- `VideoService.loadPlayer(asset:)` — AVPlayer setup, metadata extraction

**UI Components:**
- Clipboard monitor (UIPasteboard in SwiftUI)
- Loading state spinner
- Error alert with retry
- Video player in modal (using AVPlayerViewController wrapper)

## Wikilinks

- [[API_Contract]] — Extract endpoint spec
- [[Architecture_Spec]] — Service architecture
- [[Epic_Breakdown]] — Full plan
- [[Dashboard]] — Sprint tracking
- [[Blockers]] — yt-dlp IP blocking blocker

## Design Updates (2026-04-12)

Phase 5 finalized 6 design decisions affecting Epic 3 implementation:

- **CREATE GIF button loading ring** → Two-state loading indicator
  - State 1: Indeterminate spinner during extraction (waiting for backend API response)
  - State 2: Determinate progress ring during download (streaming video from signed URL)
  - Transition: After API responds with video URL, spinner → progress ring
  - Sprint 2 story: Implement loading ring state machine in HomeViewModel

---

## Notes

This epic is blocked waiting for EXTRACT-CONFIG resolution. Once yt-dlp can successfully extract video from at least one platform, this epic becomes unblocked and can proceed immediately. Loading ring implementation is decoupled from backend availability and can begin immediately.
