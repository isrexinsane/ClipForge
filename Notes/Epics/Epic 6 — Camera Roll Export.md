# Epic 6 — Camera Roll Export

**Status:** ✅ Complete (3/3 stories)

## Overview

Complete the export flow: save GIF to Photos library, display export success state with GIF preview and share options, and maintain a visual history of created GIFs.

| Story | Title | Status | Acceptance Criteria |
|-------|-------|--------|-------------------|
| STORY-021 | Camera Roll Save — PHPhotoLibrary Integration | ✅ Complete | Saves GIF to Photos library with .addOnly permission, handles permission states, reports save status |
| STORY-022 | Export Success State — GIF Preview, Share, Done | ✅ Complete | Displays looping GIF preview, shows free tier remaining count, Share button with UIActivityViewController, Done button closes modal |
| STORY-023 | Media Library — GIF History Grid | ✅ Complete | 2-column LazyVGrid of created GIFs, UserDefaults persistence, tap opens iOS share sheet, in-app detail view deferred to v1.2+ |

## Camera Roll Save (STORY-021)

**PHPhotoLibrary Integration**

- Request `.addOnly` permission on first export attempt
- Handle three permission states: `.authorized`, `.denied`, `.notDetermined`
- Add GIF as `PHAssetMediaType.video` (GIFs are video in Photos)
- Show inline error if permission denied: "Photos permission required to save GIFs"
- Log system error code if PHPhotoLibrary fails (for debugging)

## Export Success State (STORY-022)

**In-Modal UI (No New Screen)**

After encoding completes and GIF saves to Photos:

| Element | Behavior |
|---------|----------|
| **Video area** | Displays looping GIF preview (unbound loop, ~15 FPS playback) |
| **Trim bar** | Disappears; replaced by full-screen GIF preview |
| **Free tier notice** | Text label: "0 of 1 free GIFs remaining today" (or "Unlimited — Premium" if subscribed) |
| **Share button** | Vermillion fill; taps UIActivityViewController with GIF file, subject "Created with ClipForge" |
| **Done button** | White outline; closes TrimModalView and returns to HomeView |

**Copy template:** "Share this GIF on your favorite app" (above Share button)

## Media Library — GIF History (STORY-023)

**Gallery View (Tab 2)**

- **Layout:** 2-column LazyVGrid with 4px spacing
- **Tile size:** Square; aspect ratio 1:1; clipped square GIF thumbnail
- **Data source:** UserDefaults key `"gif_history"` stores JSON array of `{fileUrl, createdAt, title?}`
- **Persistence:** Each GIF exported adds entry to UserDefaults (append-only for MVP)
- **Interaction:** Tap tile → opens iOS share sheet (UIActivityViewController) with GIF file
- **No in-app detail:** Gallery is visual index only; all downstream actions (share, save, delete) via iOS share sheet
- **Empty state:** "No GIFs yet. Create one on the Home tab to get started."
- **MVP scope:** View only; delete, rename, and management UIs deferred to v1.2+

**UserDefaults Schema**

```json
{
  "gif_history": [
    {
      "fileUrl": "/path/to/gif/xyz.gif",
      "createdAt": "2026-04-12T14:35:22Z",
      "title": "Coach reaction" // optional, may be null
    }
  ]
}
```

## Design Details

- **Font:** Title "Media Library" in JetBrains Mono Bold 24pt, body text in Inter Regular 14pt
- **Spacing:** 12pt margin (left/right/top), 4pt inter-tile gap
- **Color:** Tiles have 1pt border (system gray), corner radius 4pt
- **Load fallback:** If GIF missing from disk, show placeholder tile with question mark
- **Max history:** No limit in MVP (v1.2 will add configurable max, auto-cleanup)

## Dependencies

✅ [[Epic 5 — GIF Encoding Engine]] — Provides encoded GIF data  
✅ [[Epic 4 — Trim Interface]] — TrimModalView contains export success state UI  

## Wikilinks

- [[Dashboard]] — Sprint tracking and phase progress
- [[Epic_Breakdown]] — Full 11-epic plan with dependencies
- [[Screen_Inventory]] — Visual specs for Export Success State (in-modal), Media Library Gallery
- [[Design_Decisions]] — Export success as in-modal state (no separate screen), Media Library as visual index only

## Notes

**Export success is an in-modal state:** The TrimModalView transitions from trimming (with trim bar) to preview (with GIF looping) to export success (with Share and Done buttons). No new screen is opened. This keeps the user's mental model simple: "I opened a tool, it did its thing, here's the result, now I close it."

**Gallery interaction pattern:** Tap opens iOS share sheet directly. No in-app detail view or edit UI. MVP is intentionally lean; management features come in v1.2+ after validating basic use patterns in the wild.

**Premium unlock:** Share button text and Done button styling are identical for free and premium users. The difference is the watermark (STORY-020 skips watermark for premium). No separate "premium export" UI.
