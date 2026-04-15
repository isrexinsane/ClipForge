---
title: "ClipForge — Session Handoff v2"
date: 2026-04-11
session: "Phase 5 UI Prototyping — Trim Modal + Freemium Model Revision"
status: In Progress
agent: PM / Architect
supersedes: Session_Handoff_2026-04-11.md (v1)
---

# ClipForge Session Handoff — April 11, 2026 (v2)

Hand this document to Cowork along with the prompt at the bottom. Cowork should update CLAUDE.md, PRD.md, Architecture_Spec.md, API_Contract.md, Epic_Breakdown.md, and Master_Checklist.md with all confirmed decisions below. Sync all changes to the Obsidian vault.

---

## 1. Confirmed Design Decisions (Update or Override Existing Documents)

### 1.1 GIF Quality Presets — REMOVED

**Original (PRD F-06):** Three-tier preset system: Standard (≤5 MB, 12 FPS, 480px), Discord (≤10 MB, 15 FPS, 640px), High Quality (≤25 MB, 20 FPS, 720px, premium only).

**New decision:** Presets eliminated entirely. Replaced with a single auto-optimized encoding target.

**New spec — "Works Everywhere" encoding:**

- Target: ≤8 MB for every GIF output
- Rationale: 8 MB clears Discord non-Nitro (10 MB limit), Twitter/X (15 MB), iMessage (no practical limit), and Messenger (25 MB). No user action required.
- The encoder automatically adjusts frame rate, dimensions, and compression to hit the target. If a short clip fits at 15 FPS and 640px, it uses that. If a longer clip needs 10 FPS and 480px, it adjusts silently.
- No user-facing settings screen. No preset selector. No GIF settings step between trim and export.
- The user trims → taps one button → GIF encodes and exports. One less screen in the flow.

**Documents affected:**

- PRD.md: Remove F-06 (Size Presets) and all AC-06.x acceptance criteria. Replace with single auto-encode spec.
- Architecture_Spec.md §4.4 and §8.2: Replace three-tier preset parameters with single ≤8 MB auto-optimize target.
- CLAUDE.md: Update GIF Encoding Parameters section — remove three-tier preset table, replace with single "Works Everywhere" spec.
- CLAUDE.md: Update Quick Reference: Key Decisions table — change "GIF presets" row.
- Epic_Breakdown.md: Simplify Epic 5 (GIF Encoding Engine) — remove preset selection stories, remove AC-06.x references.
- Master_Checklist.md: Update PRD ↔ Architecture alignment table for F-06 row. Remove Gap #4 (estimated file size calculation) — no longer needed without preset selector.

### 1.2 Freemium Model — REVISED

**Original (PRD F-08):** Free tier: 3 GIF exports per day. Premium: $1.99/month or $9.99/year. Premium benefits: unlimited exports, HD quality preset, no watermark, MP4 export.

**New decision:**

| Element | Original | New |
|---------|----------|-----|
| Daily free limit | 3/day | 1/day |
| Price points | $1.99/mo + $9.99/yr | $9.99/yr only |
| Premium "HD" unlock | Yes (High Quality preset) | No (everyone gets the same auto-optimized quality) |
| Premium benefits | Unlimited + HD + no watermark + MP4 | Unlimited + no watermark (+ MP4 in v1.1) |

**Rationale:** 1/day creates tighter conversion pressure. The second GIF attempt in a single session — which happens quickly for Dante (multiple GIFs per game) and even Tyler (two funny moments in one group chat session) — hits the paywall while the app still feels novel. $9.99/year as the sole price point eliminates decision friction. One price, one button. The HD preset unlock is no longer relevant because presets are removed.

**Documents affected:**

- PRD.md: Update F-08 acceptance criteria (AC-08.1: change "3" to "1", AC-08.2: update counter display, AC-08.4: remove $1.99/mo option).
- PRD.md §8 (Monetization): Update revenue projection context to reflect 1/day and $9.99/yr only.
- CLAUDE.md: Update Quick Reference: Key Decisions table — change "Monetization" row.
- Architecture_Spec.md §3.5: Update dailyExportCount description to reflect 1/day limit.
- Epic_Breakdown.md: Simplify Epic 8 (Subscriptions) — one product instead of two.

### 1.3 Watermark — LOGOMARK APPROACH

**Original (PRD F-09):** Semi-transparent "Made with ClipForge" text watermark in bottom-right corner.

**New decision:** Replace text watermark with app logomark asset. Same position (bottom-right), same semi-transparency (40-50% opacity), approximately 10-15% of frame width.

**Implementation:** The logomark is a single small PNG bundled in the app (under 50 KB). CoreGraphics composites it onto each frame during encoding — one extra draw call per frame, negligible performance impact, no measurable file size increase. For MVP, use a simple text treatment ("ClipForge" in monospace, semi-transparent white) until final branding/logo is designed. The encoding pipeline doesn't change when the asset is swapped.

**Documents affected:**

- PRD.md: Update F-09 and AC-09.x to reference logomark instead of text.
- Architecture_Spec.md §4.4 step 4: Update watermark compositing description.
- Epic_Breakdown.md: Update Epic 7 watermark story to reference logomark asset.

### 1.4 Trim Modal — iOS Photos Editor Pattern

**Original (Session Handoff v1 §2.6):** Full-screen modal with custom trim interface on off-white background.

**New decision:** Trim modal now follows the iOS Photos/Camera video editor pattern:

- **Background:** Pure black (`000000`). No gradient. No off-white.
- **Video area:** Media fills the center of the screen edge-to-edge, no rounded corners, no padding. Black letterboxing above and below for non-matching aspect ratios.
- **Top bar:** Volume toggle (Liquid Glass Symbol button with `speaker.wave.2.fill` SF Symbol) top-left. "Cancel" (Liquid Glass Text button) top-right. No "TRIM" title — the interface is self-explanatory.
- **Trim bar:** iOS Photos-style trim bar below the video area. Single rounded rectangle container (`3A3A3C`), divided into play button section (left ~50px) and filmstrip/timeline section (remainder). Play button uses `play.fill` SF Symbol. Filmstrip is a single solid rectangle (`4A4A4C`). Chevron handles (`chevron.compact.left` and `chevron.compact.right` from SF Symbols) at filmstrip edges with connecting top/bottom border forming a selection frame. White playhead line with drag nub.
- **Below trim bar:** Duration readout ("2.4s", JetBrains Mono Bold 32px, white), then NEXT/CREATE GIF action button (vermillion pill).
- No GIF settings screen. Presets removed (see §1.1). User goes directly from trim to encode/export.

**Documents affected:**

- PRD.md: Update Flow 3 (Configure GIF Settings) — remove entirely or merge into Flow 2/Flow 4. Update Flow 2 to reflect new trim modal layout.
- Architecture_Spec.md §3.2: Update navigation architecture — remove GIF Settings screen from NavigationStack description.
- Epic_Breakdown.md: Epic 4 (Trim Interface) updated to reference iOS Photos pattern. No separate "GIF Settings" story needed.

### 1.5 VideoTrimmerControl — Development Reference Flagged

**Source:** `https://github.com/AndreasVerhoeven/VideoTrimmerControl`

**Assessment:** MIT-licensed Swift UIKit control that replicates the iOS Photos trim bar behavior. Single-file implementation (VideoTrimmer.swift + VideoTrimmerThumb.swift). Handles chevron drag handles, filmstrip thumbnail generation from AVAsset, playhead/progress indicator, scrubbing, and zoom-in-on-trim precision feature.

**Decision:** Flagged for evaluation during Epic 4 development. The SM agent should assess whether to integrate directly (and restyle) or use as architectural reference. Either path saves significant development time on the trim interface.

**Documents affected:**

- CLAUDE.md: Add to Cross-References or a new "Development References" section.
- Epic_Breakdown.md: Add note to Epic 4 referencing this repo.

---

## 2. Figma Project State (Updated)

### 2.1 Frame Status

| Frame Name | Status | Notes |
|-----------|--------|-------|
| 01 Home | ~85% complete | Unchanged from v1. CTA button needs concave treatment. Menu button is placeholder. |
| 02 Media Library | ~70% complete | Unchanged from v1. Needs card content, date captions, empty state. |
| 03 Trim Modal | ~60% complete | MAJOR REDESIGN. Black background, volume button (Liquid Glass + SF Symbol), Cancel button (Liquid Glass Text), video area placeholder, trim bar container with play button, filmstrip rectangle, chevron handles, playhead all done. **Needs:** connecting top/bottom borders on chevron selection frame, duration readout below bar, NEXT button, overall spacing refinement. |
| 04 Encoding Progress | Not started | Circular progress ring, percentage, "Creating your GIF..." text. May integrate into trim modal as state change. |
| 05 Export Success | Not started | GIF preview loop, file size readout, Share and Done buttons, free tier remaining count ("0 of 1 free GIFs remaining today"). |

### 2.2 New Assets Sourced

| Asset | Source | Usage |
|-------|--------|-------|
| SF Symbols (text objects) | `figma.com/community/file/1549047589273604548` | Volume icon (`speaker.wave.2.fill`), play button (`play.fill`), chevrons (`chevron.compact.left`, `chevron.compact.right`). Sourced as text/font characters — resize via font size, flatten (⌘+E) to convert to vector if needed. |
| Apple Photos iOS (community file) | `figma.com/community/file/1374221671141407670` | Visual reference for Photos app UI. Pre-iOS 26 but trim bar anatomy is architecturally identical. |
| iOS 26 Video Player (Liquid Glass) | `figma.com/community/file/1515346123629963655` | Reference for Liquid Glass video player controls. |
| VideoTrimmerControl screenshots | `github.com/AndreasVerhoeven/VideoTrimmerControl` | Visual reference for trim bar anatomy. Also flagged for Epic 4 development. |

### 2.3 Color Palette Update (Trim Modal Only)

| Role | Hex | Opacity | Usage |
|------|-----|---------|-------|
| Trim modal background | `000000` | 100% | Full black, matching iOS Photos/Camera editor |
| Trim bar container | `3A3A3C` | 100% | Apple's dark system grey |
| Filmstrip | `4A4A4C` | 100% | Slightly lighter grey representing video frames |
| Chevron handles + selection border | `FFFFFF` | 30% | Frosted glass effect on handle rectangles and connecting borders |
| Playhead | `FFFFFF` | 100% | Solid white vertical line with drag nub |
| Duration readout | `FFFFFF` | 100% | White text on black background |
| Trim action elements (NEXT button) | `EF3340` | 100% | Vermillion, consistent with Home screen CTA |

---

## 3. Sprint 2 Backlog (Unchanged from v1)

| Item | Priority | Description |
|------|----------|-------------|
| AUTH-FIX | Low | FastAPI returns 422 for missing API key header; should return 401 per API Contract §4 |
| EXTRACT-CONFIG | High | yt-dlp cookie/proxy configuration to resolve datacenter IP blocking on all five platforms |

---

## 4. Immediate Next Steps

### 4.1 Figma — Complete Trim Modal

1. Add connecting top/bottom borders between chevron handles (2-3px, white at 30% opacity)
2. Add duration readout: "2.4s" centered below trim bar (JetBrains Mono Bold 32px, white)
3. Add NEXT button: vermillion pill (W: 400, H: 52, corner radius 26, fill EF3340, text "NEXT" white)
4. Refine spacing and alignment of all trim bar elements

### 4.2 Figma — Encoding Progress + Export Success

Design frames 04 and 05. Decide whether they're separate frames or state changes within the trim modal.

### 4.3 Document Updates (This Handoff)

Cowork updates all project files per Section 1 above.

### 4.4 Development Phase

After Figma is complete, begin BMAD development phase. SM agent starts Epic 1 (iOS App Shell) and Epic 2 (Backend API) stories — noting Epic 2 backend is already deployed, so SM reviews completed code against stories and marks done, then moves to Epic 3 (Networking + Video Import).

---

## 5. Key File Paths (Unchanged)

| Item | Path |
|------|------|
| Project folder | `~/Library/Mobile Documents/com~apple~CloudDocs/Documents/Claude/Projects/ClipForge - iOS App Development/` |
| Backend code | `{project}/backend/` |
| iOS project | `{project}/ClipForge/` and `{project}/ClipForge.xcodeproj` |
| GitHub repo | `https://github.com/isrexinsane/ClipForge` |
| Railway dashboard | `https://railway.com/project/62e80c66-1404-4ca3-a707-926fc3a05b5d` |
| Live API | `https://clipforge-production-f27b.up.railway.app` |
| Figma file | ClipForge (Rex's Figma account, Drafts) |
| Obsidian vault | Same as project folder |
