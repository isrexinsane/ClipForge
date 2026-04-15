---
title: "ClipForge — Supplemental Handoff"
date: 2026-04-12
session: "Phase 5 Wrap-Up — Final Design Decisions"
status: Complete
agent: PM
supplements: Session_Handoff_2026-04-11_v2.md
---

# ClipForge Supplemental Handoff — April 12, 2026

Hand this document to Cowork along with the prompt at the bottom. These decisions finalize Phase 5 (UI Prototyping) and should be logged in CLAUDE.md's Design Decisions Log and reflected in the relevant BMAD documents.

## 1. Confirmed Design Decisions

### 1.1 CREATE GIF Button — Loading Ring Interaction

**Decision:** When the user taps CREATE GIF on the Home screen (after a supported URL is detected on the clipboard), the button's circular border becomes a progress ring indicating video import progress.

**Behavior:**

- User taps the CREATE GIF button
- The app sends the URL to the backend API (`POST /v1/extract`)
- The button's circular border stroke animates clockwise: vermillion (`EF3340`) stroke grows around the circumference, proportional to download progress
- The button remains centered on screen. The "CREATE GIF" label below it could change to "PREPARING..." or remain static (Developer agent discretion)
- At 100% completion (video fully received), the app transitions to the Trim Modal with the video loaded
- On failure, the ring resets to its default state and an error message appears below the button (per PRD F-10 error handling specs)

**Rationale:** Users keep their eyes on the element they just tapped. A progress ring on the button itself provides a visual anchor during the 3-15 second wait, rather than a dislocated spinner or loading screen. The interaction feels native and intentional.

**Implementation notes:**

- SwiftUI: The button border is a `Circle()` stroke. The loading state overlays a `trim(from:to:)` modifier on the stroke, animated with the download progress value
- Progress value source: `URLSession` download task progress via `Progress` observation
- The signed URL from `/v1/extract` response triggers a second download from `/v1/media/{file_id}` — the progress ring tracks this second download, not the extraction API call (which doesn't report progress). During the extraction call itself (typically 2-8 seconds), the ring can show an indeterminate animation (slow pulse or rotation) since the server doesn't stream progress for yt-dlp extraction

**Documents affected:**

- CLAUDE.md: Add to Design Decisions Log
- PRD.md: Add to Flow 1 (step 6) — replace generic "loading indicator" with CREATE GIF button progress ring description
- Architecture_Spec.md §4.2: Add progress ring to Phase 2 data flow description
- Epic_Breakdown.md: Epic 3 (Networking + Video Import) should include a story for the button loading ring animation

---

### 1.2 Encoding Progress — State Within Trim Modal

**Decision:** Encoding progress is NOT a separate screen. It is a state change within the Trim Modal (Frame 03).

**Behavior:**

- User taps CREATE (the action button at the bottom of the Trim Modal)
- The CREATE button transforms into a circular progress ring: vermillion (`EF3340`) stroke on black background
- Percentage displayed in center: JetBrains Mono Bold, white, updates as encoding progresses
- Text below the ring: "Creating your GIF..." in JetBrains Mono Medium ~14px, `968C83` (secondary text color on dark background)
- The trim bar and duration readout remain visible above (user can see what they're encoding)
- The volume button and Cancel button remain in the top bar (Cancel aborts encoding and returns to trim state)
- On completion, the modal transitions to the Export Success state (see §1.3)

**Rationale:** No screen transition needed. The user stays in the same modal context. The progress ring replaces the button they just tapped, maintaining spatial continuity.

**Documents affected:**

- CLAUDE.md: Add to Design Decisions Log
- PRD.md: Update Flow 4 step 1 — reference in-modal progress ring, not a separate screen
- Epic_Breakdown.md: Epic 5 (GIF Encoding Engine) stories should specify in-modal progress state, not a separate view

---

### 1.3 Export Success — State Within Trim Modal

**Decision:** Export success is NOT a separate screen. It is a state change within the Trim Modal (Frame 03).

**Behavior:**

- Encoding completes → GIF saved to camera roll automatically (permission request on first export)
- The video area (center of modal) now shows the finished GIF playing in a loop
- The trim bar disappears
- Below the GIF preview:
  - File size and dimensions readout (e.g., "3.2 MB · 480 × 270") in JetBrains Mono Medium ~14px, white
  - Two buttons side by side: "Share" (opens iOS share sheet with GIF attached) and "Done" (dismisses modal, returns to Home)
  - Button style: both are pill-shaped. Share is vermillion fill (`EF3340`), Done is outline/ghost style (white border, no fill, white text)
- On free tier: small text above the buttons: "0 of 1 free GIFs remaining today" in `968C83`
- The volume button in the top bar can toggle GIF playback audio (GIFs are silent, but the source may have had audio — this is a no-op for GIF but maintains UI consistency)
- Cancel button in top bar changes to... nothing (or remains as a secondary dismiss path equivalent to Done)

**Rationale:** Same modal, same context. The user's mental model is "I opened a tool, it did its thing, here's the result, now I close it." No navigation stack to manage.

**Documents affected:**

- CLAUDE.md: Add to Design Decisions Log
- PRD.md: Update Flow 4 steps 4-8 — reference in-modal success state
- Architecture_Spec.md §3.2: Confirm no ExportView needed as separate view — it's a state within TrimView/TrimViewModel
- Epic_Breakdown.md: Epic 6 (Camera Roll Export) stories should specify in-modal success state

---

### 1.4 Media Library Tile Interaction

**Decision:** Tapping a tile in the Media Library (Frame 02) immediately opens the iOS share sheet with the selected GIF attached. No in-app detail view, no GIF management UI in MVP.

**Rationale:** Keep MVP lean. The gallery is a visual index. iOS share sheet handles all downstream actions (share to Messages, save to Files, AirDrop, etc.). In-app GIF management is a candidate for the post-launch roadmap (v1.2+).

**Documents affected:**

- CLAUDE.md: Add to Design Decisions Log
- PRD.md: Add as a note under F-22 (GIF history/library) in the post-launch features table, clarifying that MVP Media Library is view-only with share sheet interaction
- Epic_Breakdown.md: If Media Library has a story, specify share sheet as the only tile interaction

---

### 1.5 Menu Button (Home Screen)

**Decision:** The "+" button in the top-right of the Home screen opens a standard iOS context menu (UIMenu / SwiftUI `.contextMenu` or `.menu`) with three items:

1. Restore Purchase — triggers StoreKit 2 restore flow
2. Privacy Policy — opens privacy policy URL in Safari
3. About ClipForge — opens a small modal with app version, copyright disclaimer ("ClipForge is intended for personal, non-commercial use of content you have the right to use"), and a link to the privacy policy

No Figma mockup needed. Standard iOS menu pattern.

**Documents affected:**

- CLAUDE.md: Add to Design Decisions Log
- Epic_Breakdown.md: Add a story within Epic 1 (App Shell) or Epic 9 (Onboarding/Polish) for menu implementation

---

### 1.6 Phase 5 (UI Prototyping) — COMPLETE

**Figma file status:**

- Frame 01 (Home): ~85% complete. Establishes visual language.
- Frame 02 (Media Library): ~70% complete. Establishes grid pattern and swipe navigation.
- Frame 03 (Trim Modal): ~75% complete. Establishes iOS Photos editor pattern.
- Frame 04: Renamed to "04 - Encoding Progress (state within Trim Modal)" — no separate design needed.
- Frame 05: Renamed to "05 - Export Success (state within Trim Modal)" — no separate design needed.

**How the Developer agent uses Figma:** The Figma file is not directly consumed by Claude Code. The SM agent writes stories that reference the visual language, interaction patterns, and specific design decisions captured in CLAUDE.md and the handoff documents. If the Developer agent needs to see a specific screen, Rex screenshots it from Figma and pastes it into the Claude Code conversation.

**Documents affected:**

- CLAUDE.md: Update BMAD Phase Tracker — Phase 5 status: ✅ COMPLETE, completed 2026-04-12. Key artifacts: Figma prototype (3 frames: Home, Media Library, Trim Modal). Encoding Progress and Export Success designed as in-modal states, documented in handoff.

---

## 2. Figma Frame Renaming (Rex Action Item)

In Figma, rename the last two frames:

- Frame 04 → "04 - Encoding Progress (state within 03)"
- Frame 05 → "05 - Export Success (state within 03)"

Optionally add a text note inside each frame: "Not a separate screen. Implemented as state change within Frame 03 (Trim Modal). See project handoff docs for specs."

---

## 3. Next Phase

Phase 6: Development begins. SM agent writes stories for:

- Epic 1 (iOS App Shell) — project scaffolding, navigation structure, MVVM setup
- Epic 2 (Backend API) — already deployed; SM reviews and marks stories complete
- Epic 3 (Networking + Video Import) — first new code connecting iOS client to live backend, includes CREATE GIF loading ring
