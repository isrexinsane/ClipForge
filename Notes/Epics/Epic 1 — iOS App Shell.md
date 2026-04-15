# Epic 1 — iOS App Shell

**Status:** ✅ Complete (2026-04-10)

## Stories Completed

| Story | Title | Status |
|-------|-------|--------|
| STORY-001 | Xcode project scaffolding and build configuration | ✅ |
| STORY-002 | MVVM folder structure and service stubs | ✅ |
| STORY-003 | Navigation structure with placeholder screens | ✅ |

## Key Outcome

SwiftUI project with a clean foundation for all downstream features:

- **Navigation:** Two-page swipeable layout (Home ↔ Gallery) + full-screen modal sheets for trim and export workflows
- **Architecture:** MVVM folder structure with four service modules
  - `Models/` — data structures (Video, GIF, ExportResult, etc.)
  - `Views/` — SwiftUI screens (HomeView, GalleryView, ModalViews)
  - `ViewModels/` — state management (HomeViewModel, GalleryViewModel, TrimViewModel)
  - `Services/` — business logic stubs (VideoService, APIClient, GIFEncoder, StorageManager)
  - `Utilities/` — helpers (Extension, Constants, Logger)
- **Build Config:** Xcode project configured, iOS 17+ deployment target, SwiftUI previews enabled

## Wikilinks

- [[Epic_Breakdown]] — Full epic plan
- [[Dashboard]] — Sprint overview
- [[BMAD_LOG]] — Decision log
- [[Sprint 1 Retrospective]] — What we learned

## Design Updates (2026-04-12)

Phase 5 finalized 6 design decisions affecting Epic 1 implementation:

- **Menu button** → Standard iOS context menu (long-press on navigation area)
  - Items: "Restore Purchase", "Privacy Policy", "About"
  - Action: Show standard UIMenu with appropriate navigation targets
  - Sprint 2 story: Add menu button to HomeView header

---

## Next Steps

Waiting for Epic 2 completion. Epic 3 (Video Import Flow) will flesh out `VideoService` and `APIClient` stubs. Sprint 2 begins with menu button user story.
