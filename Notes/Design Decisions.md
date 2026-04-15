# Design Decisions

This note indexes all design decisions for ClipForge across multiple handoff documents. Each decision is documented in depth in source files and summarized here.

> [!info]
> **Current design spec:** See [[Session_Handoff_2026-04-11_v2]] (latest)  
> **Superseded:** [[Design_Decisions]] (v1) — replaced by v2  
> **System brief:** [[Design System]] — colors, typography, spacing, components

---

## Design Decision Registry

All decisions are final unless explicitly revised. Updated as new decisions are made.

| # | Decision | Choice | Rationale | Source |
|---|----------|--------|-----------|--------|
| 1 | GIF Presets | Single "Works Everywhere" (≤8 MB) | 8 MB clears Discord, Twitter, iMessage, Messenger. Removes one screen + one decision from UX. | Session_Handoff_v2 §1.1 |
| 2 | Freemium Model | 1/day free, $9.99/yr unlimited + no watermark | Tighter conversion pressure. Single price eliminates decision friction. | Session_Handoff_v2 §1.2 |
| 3 | Watermark Style | Logomark PNG (not text) | More professional. Asset swappable when branding finalizes. | Session_Handoff_v2 §1.3 |
| 4 | Trim Modal Pattern | iOS Photos/Camera editor (black bg, edge-to-edge video, chevron handles) | Matches native editing pattern. Zero learning curve. | Design_Decisions §2.1 |
| 5 | GIF Settings Screen | REMOVED | Auto-encoding pipeline needs no UI. Trim → Export → Done. | Design_Decisions §2.2 |
| 6 | Navigation Model | 2 pages (Home ↔ Gallery) + modal sheets | Simpler than 5-screen stack. Matches Seal app pattern. | Design_Decisions §2.1 |
| 7 | Color Mode | Light mode with vermillion gradient | Warm off-white (#F5F0EB) + top-down #EF3340 gradient. Ronin Art House brand identity. | Design_Decisions §2.3 |
| 8 | Tab Bar | REMOVED | Swipe navigation + animated page dots is cleaner. | Design_Decisions §2.4 |
| 9 | Typography | JetBrains Mono (display/UI) + Inter (body) | Monospace for precision-tool identity; humanist for readability. Both SIL-licensed. | Design_Decisions §3.5 |
| 10 | Home Screen CTA | Single button + auto clipboard detection | Fastest possible UX. No text field, no paste UI. Button state changes on supported URL detect. | Design_Decisions §2.2 |
| 11 | User Accounts | None (StoreKit 2 → iCloud) | Zero data collection. No login UI. Premium state syncs via iCloud. | Design_Decisions §2.7 |
| 12 | Video Delivery | Signed URL via /v1/media (always) | Single code path on iOS. No base64 inline mode. Keeps extraction response lightweight. | API_Contract §3.2 |
| 13 | YouTube Support | EXCLUDED from MVP | Highest App Store rejection risk. May revisit post-launch. | Feasibility Report §3.3 |
| 14 | Backend Hosting | Railway or Fly.io | Low cost ($5–20/mo). Simple Python deploy. Auto-scaling. | Feasibility Report §5.1 |

---

## Design System Reference

- **Color Palette:** Vermillion gradient on warm off-white. See [[Design System]]
- **Typography:** JetBrains Mono (medium, bold for headers) + Inter (regular, medium)
- **Spacing:** iOS standard (8px increments)
- **Components:** See Design System for button, input, modal, navigation specs

---

## Recent Updates

**April 11, 2026 (Session Handoff v2):**
- Confirmed GIF preset removal (→ single auto-optimized output)
- Revised freemium pricing (1/day free, $9.99/yr flat)
- Watermark changed to logomark PNG
- Trim modal redesigned to iOS Photos pattern
- All changes propagated to PRD, Architecture Spec, Epic Breakdown, Master Checklist

---

## Wikilinks

- [[Session_Handoff_2026-04-11_v2]] — Latest design spec document
- [[Design_Decisions]] (v1) — Original decision log (superseded by v2)
- [[Design System]] — Color, typography, spacing, components
- [[Dashboard]] — Current project status
- [[PRD]] — Product requirements (reflects all decisions)
- [[Architecture_Spec]] — Technical architecture aligned with design decisions

---

**Last updated:** 2026-04-11  
**Next review:** When design changes are requested or design phase resumes
