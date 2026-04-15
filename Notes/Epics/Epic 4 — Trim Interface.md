# Epic 4 — Trim Interface

**Status:** ✅ Complete (5/5 stories)

## Scope

Build the video trimming interface — the core editing feature that differentiates ClipForge from a pure video saving tool.

## Stories

| Story | Description | Status |
|-------|-------------|--------|
| [[STORY-014]] | TrimViewModel — Core Trim State Management | ✅ |
| [[STORY-015]] | Filmstrip Thumbnail Generator | ✅ |
| [[STORY-016]] | TrimBarView — Timeline Scrubber UI | ✅ |
| [[STORY-017]] | Duration Readout and Color Warnings | ✅ |
| [[STORY-018]] | CREATE Button and Next-Step Trigger (+ font setup) | ✅ |

## Design Pattern

iOS Photos/Camera editor pattern:
- Black background, edge-to-edge video preview
- iOS-style trim bar at bottom with chevron handles (in, out)
- Filmstrip thumbnail scrubber
- Centered playhead
- Play button overlay

**Design Reference:** [[Session_Handoff_2026-04-11_v2]] § Trim Modal redesign

## Dev Reference

**VideoTrimmerControl (MIT License)**
- https://github.com/AndreasVerhoeven/VideoTrimmerControl
- Swift UIKit control — used as **architectural reference only**, not imported as dependency
- Reference for: drag gesture handling, thumbnail generation patterns, zoom-on-trim behavior

## Key Constraints

- Minimum trim duration: 0.5 seconds
- Maximum trim duration: 30 seconds
- Duration color warnings: ≤10s normal (white), >10s warning (orange), >15s danger (red)
- Pure SwiftUI — no UIKit bridging
- isNextEnabled true when handle moved or source ≤30s

## Dependencies

- ✅ [[Epic 3 — Video Import Flow]] — video must be loaded before trim
- ✅ STORY-013 (VideoPlayerManager + Trim Modal Shell) — shell exists
- Depends on: AVFoundation (native framework)

## Wikilinks

- [[Design_Decisions]] — Modal and trim bar decisions
- [[Session_Handoff_2026-04-11_v2]] — Current design spec
- [[Screen_Inventory]] — Frame 03 (Trim Modal) specs
- [[Architecture_Spec]] — AVFoundation integration
- [[Epic_Breakdown]] — Full plan
- [[Dashboard]] — Sprint tracking
