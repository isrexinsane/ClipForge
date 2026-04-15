# Epic 5 — GIF Encoding Engine

**Status:** ✅ Complete (2/2 stories)

## Overview

Implement on-device GIF encoding with automatic optimization — no user-facing settings, no presets. Two stories implement the core encoding pipeline and orchestration layer.

| Story | Title | Status | Acceptance Criteria |
|-------|-------|--------|-------------------|
| STORY-019 | GIFEncoder — Core Encoding Pipeline | ✅ Complete | Extracts frames, resizes per tier, optimizes palette, writes GIF via CGImageDestination, manages two-pass resize |
| STORY-020 | ExportViewModel — Encoding Orchestration | ✅ Complete | Orchestrates encoding, displays determinate progress ring, never blocks export, handles size re-optimization |

## "Works Everywhere" Encoding Spec

Single automatic optimization target: **≤8 MB file size**

| Parameter | Value | Behavior |
|-----------|-------|----------|
| **Frame rate** | 10–15 FPS | Auto-selected based on trim duration and resolution |
| **Max width** | 480–640 px | Auto-selected; aspect ratio preserved |
| **Color depth** | 256 colors | GIF format limit |
| **Max duration** | 15 seconds | Hard cap enforced at trim step |
| **Watermark** | Logomark PNG | Bottom-right, 40–50% opacity, free tier only |

**Why 8 MB?** Clears Discord non-Nitro (10 MB), Twitter/X (15 MB), iMessage, Messenger (25 MB). User doesn't choose — encoder picks automatically.

## FPS/Width Tiers (Auto-Selected)

Three tiers applied automatically based on trimmed range duration:

| Duration | FPS | Width | Rationale |
|----------|-----|-------|-----------|
| ≤10 seconds | 15 FPS | 640px | Short clips benefit from smooth motion; higher quality justified by smaller frame count |
| >10s, ≤20s | 12 FPS | 480px | Medium clips balance smoothness and file size |
| >20s | 10 FPS | 400px | Longer clips (rare post-15s cap) need aggressive optimization |

## Encoding Pipeline

1. **Frame extraction:** AVAssetImageGenerator extracts frames at auto-selected FPS from trimmed AVAsset
2. **Two-pass resize:** First pass measures optimal dimensions; second pass scales all frames to preserve aspect ratio and fit within tier width
3. **Watermark compositing:** Logomark PNG applied bottom-right at 40–50% opacity (free tier only; premium skips this step)
4. **Palette optimization:** Global color palette computed across all frames using ImageIO, color reduction to 256 (GIF limit)
5. **GIF assembly:** CGImageDestination writes frames sequentially with inter-frame delay = 1/fps
6. **Size check:** If output exceeds ≤8 MB, automatically reduce frame rate → reduce width → apply lossy compression (in that order)
7. **Progress reporting:** Determinate progress ring updated every 50ms during encoding
8. **Save:** Finished GIF passed to ExportViewModel for Photos library save (STORY-021)

**Never block export:** Encoding happens on background thread; UI remains responsive at all times. Progress ring updates on main thread.

## Key Frameworks

- `ImageIO` / `CGImageDestination` — Native GIF writing, no external libraries
- `AVAssetImageGenerator` — Frame extraction with specified timestamps
- `CoreGraphics` — Watermark compositing via CGContext
- `AVFoundation` — AVAsset trimmed range management

## Dependencies

✅ [[Epic 4 — Trim Interface]] — Trimmed range must be established before encoding begins  
✅ [[STORY-013]] — VideoPlayerManager holds AVAsset reference  
✅ [[STORY-014]] — TrimViewModel provides trimmed time range  

## Design Constraints

- **Encoding as in-modal state:** No new screen; progress displays in TrimModalView overlaying trimmed video preview
- **Progress ring:** Determinate circle (0–100%), white stroke, "Creating GIF..." label during encoding
- **No user control:** Encoding parameters (FPS, width, palette) are non-configurable; codec choices are automatic
- **Watermark asset:** Logomark PNG bundled in Xcode; swappable without code changes when branding finalizes

## Wikilinks

- [[Dashboard]] — Sprint tracking and phase progress
- [[Epic_Breakdown]] — Full 11-epic plan with dependencies
- [[Architecture_Spec]] — Section §4.4, GIF encoding architecture
- [[Design_Decisions]] — Session handoff decisions (preset removal, in-modal encoding state)

## Notes

This epic delivers the encoding engine; STORY-021 (Camera Roll Save) and STORY-022 (Export Success State) in Epic 6 handle persistence and UI feedback. Encoding completes silently; the user sees only the progress ring and then the success modal.
