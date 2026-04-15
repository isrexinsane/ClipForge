# Epic 6 — Export & Gallery

**Status:** ⬜ Not Started

## Scope

- Export encoded GIF to Photos library
- Save GIF metadata to local database (timestamp, source URL, original trim range)
- Display gallery of saved GIFs on Gallery tab
- Share GIF via system share sheet (Messages, Mail, Notes, etc.)
- Delete GIF from gallery with confirmation

## Dependencies

- ✅ [[Epic 5 — GIF Encoding Engine]] — encoded GIF must exist before export

## Implementation

- **Photos Save:** PHPhotoLibrary save with custom album "ClipForge"
- **Local Database:** Core Data or Codable JSON (lightweight; no iCloud sync needed)
- **Gallery UI:** LazyVGrid of GIF thumbnails, pull-to-refresh, long-press for delete
- **Share Sheet:** UIActivityViewController wrapper

## Wikilinks

- [[Epic_Breakdown]] — Full plan
- [[Dashboard]] — Sprint tracking
- [[Architecture_Spec]] — Data persistence details

## Design Updates (2026-04-12)

Phase 5 finalized 2 design decisions affecting Epic 6 implementation:

- **Export success as in-modal state** → No separate screen
  - Modal behavior: Trim Modal remains open after encoding completes
  - Success display: Modal content transitions to success state (checkmark, "GIF Saved!")
  - Action: User taps "Save" button to close modal and return to Home
  - Text: "GIF saved to Photos" confirmation
  - Sprint 2 story: Implement success state transition within TrimModalView

- **Media Library tile → iOS share sheet** → Direct interaction
  - Gallery tile tap: Opens UIActivityViewController directly (no detail view)
  - Share options: Messages, Mail, Notes, Reminders, etc.
  - No intermediate preview screen
  - Sprint 2 story: Update GalleryView tiles to open system share sheet on tap

---

## Notes

Gallery is read-only in MVP. No editing of saved GIFs. Future: add "re-trim" flow to modify and re-export. Export flow uses in-modal state transitions (encoding → success) rather than screen navigation.
