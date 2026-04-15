---
title: "ClipForge — Master Checklist"
agent: PO (Product Owner)
phase: Planning
status: Complete
date: 2026-04-10
project: ClipForge
org: Ronin Art House
depends_on:
  - Project_Brief.md
  - PRD.md
  - Architecture_Spec.md
  - API_Contract.md
---

# ClipForge — Master Checklist

This checklist is the PO agent's validation of alignment across all planning-phase documents. Each item confirms that the Project Brief, PRD, Architecture Spec, and API Contract are consistent, or flags a conflict with a recommended resolution. The checklist is organized into four sections: Brief ↔ PRD alignment, PRD ↔ Architecture alignment, hard constraint compliance, and gap identification.

## 1. Brief ↔ PRD Alignment

### 1.1 Market Opportunity and Positioning

| Check | Status | Notes |
|-------|--------|-------|
| PRD value proposition matches Brief's market gap analysis (integrated link-to-GIF workflow) | **PASS** | PRD §1 directly restates the Brief's core finding: no iOS app combines video import-from-link with GIF creation. |
| PRD positioning as "GIF creation tool" (not "video downloader") aligns with Brief §4 | **PASS** | PRD §1 explicitly states: "It is not a video downloader. The video import exists to serve the creative workflow." |
| All three personas from Brief §3 are carried into PRD §2 with expanded usage scenarios | **PASS** | Dante, Priya, Tyler all present with detailed scenarios and tier behavior. |
| Brief's competitive landscape (Seal, ImgPlay, GIF Maker Studio, Video to GIF) reflected in PRD scope decisions | **PASS** | PRD features are scoped to fill exactly the gaps identified in Brief §2: import-from-link (Seal's territory) + trim-to-GIF (ImgPlay's territory). |

### 1.2 Risk Mitigations

| Check | Status | Notes |
|-------|--------|-------|
| Brief Risk 1 (App Store rejection) addressed in PRD compliance measures | **PASS** | PRD AC-01.5 explicitly forbids "download" in UI. PRD §3.3 excludes YouTube. PRD F-12 enforces zero data collection. |
| Brief Risk 2 (platform API changes) addressed in architecture choice | **PASS** | Server-side yt-dlp per Architecture Spec §2.2 enables instant updates. |
| Brief Risk 3 (copyright/DMCA) addressed in PRD legal compliance | **PASS** | PRD F-12, AC-12.3 includes in-app copyright disclaimer. |
| Brief Risk 4 (technical complexity) addressed by BMAD methodology | **PASS** | This is a process mitigation, not a document alignment issue. BMAD planning artifacts (this checklist included) are the mitigation in action. |
| Brief Risk 5 (competitor entry) addressed by narrow MVP scope | **PASS** | PRD §3.3 lists explicit scope exclusions to keep the MVP tight and shippable. |

### 1.3 Monetization

| Check | Status | Notes |
|-------|--------|-------|
| Brief's freemium model reflected in PRD feature gating | **PASS** | PRD F-08 defines free tier (1/day) and premium ($9.99/yr). Matches feasibility report §8. |
| Premium features in PRD match feasibility report tier breakdown | **PASS** | Unlimited exports, no watermark, MP4 export (post-launch). Aligned. |

### 1.4 Supported Platforms

| Check | Status | Notes |
|-------|--------|-------|
| Brief lists Twitter/X, Instagram, Reddit, TikTok, Twitch as MVP platforms | **PASS** | PRD F-01, AC-01.1 lists the same five platforms. |
| YouTube excluded per Brief §5 Risk 1 | **PASS** | PRD §3.3 explicitly excludes YouTube. API Contract §5.6 enforces the exclusion at the backend level. |

## 2. PRD ↔ Architecture Alignment

### 2.1 Feature-to-Architecture Mapping

| PRD Feature | Architecture Component | Status | Notes |
|-------------|----------------------|--------|-------|
| F-01: Link paste and video import | APIService → POST /v1/extract → yt-dlp backend | **PASS** | Full data flow traced in Arch Spec §4.2. API endpoint specified in Contract §3.1. |
| F-02: Clipboard detection | ClipboardMonitor (on-device, UIPasteboard) | **PASS** | Arch Spec §4.1 details the detection flow. SupportedPlatforms config matches API Contract §5 patterns. |
| F-03: Video preview player | VideoPlayerManager (AVFoundation: AVPlayer, AVPlayerItem) | **PASS** | Arch Spec §3.3 lists AVFoundation. §4.3 traces the playback flow. |
| F-04: Trim interface | TrimViewModel + AVPlayer.seek (frame-accurate) | **PASS** | Arch Spec §4.3 details handle-to-seek binding. Performance target (≤100ms) addressed in §8.2. |
| F-05: GIF encoding engine | GIFEncoder (ImageIO: CGImageDestination, CoreGraphics: AVAssetImageGenerator) | **PASS** | Arch Spec §4.4 provides the full encoding pipeline. Batch processing strategy in §8.3 addresses memory budget. |
| F-06: Size presets | GIFEncoder configuration parameters (FPS, dimensions, compression) | **REMOVED** | Replaced by single auto-optimized ≤8 MB encoding. No user-facing presets. |
| F-07: Camera roll export | ExportManager (PHPhotoLibrary) | **PASS** | Arch Spec §4.5 details the export flow including permission handling. |
| F-08: Freemium gating | FreemiumGatekeeper (UserDefaults: dailyExportCount, dailyExportDate) | **PASS** | Arch Spec §3.5 lists the UserDefaults keys. No network dependency for counter enforcement (matches PRD §6.3 offline behavior). |
| F-09: Watermark (free tier) | WatermarkCompositor (CoreGraphics text rendering) | **PASS** | Arch Spec §4.4 step 4 describes watermark compositing during encoding. |
| F-10: Error handling | ClipForgeAPIError enum mapped to Localizable.strings | **PASS** | API Contract §4 defines all error codes. Contract §7.2 provides the Swift enum. Arch Spec §5.4 establishes the strategy. |
| F-11: Onboarding flow | SwiftUI views + hasCompletedOnboarding UserDefaults flag | **PASS** | Arch Spec §3.5 includes the flag. Architecture pattern (MVVM) supports the screen flow. |
| F-12: Privacy and legal compliance | Zero third-party SDKs, zero data collection, zero user accounts | **PASS** | Arch Spec §6.2 explicitly states zero third-party iOS libraries. §3.5 confirms only non-personal data in UserDefaults. |

### 2.2 Acceptance Criteria Coverage

| PRD AC | Architecture Support | Status | Notes |
|--------|---------------------|--------|-------|
| AC-01.2: Video import ≤15s on LTE | 720p cap, synchronous API, regional VPS | **PASS** | Arch Spec §4.2 analyzes the latency budget and confirms feasibility. |
| AC-04.2: Frame-accurate trim scrubbing | AVPlayer.seek with zero tolerance | **PASS** | Arch Spec §4.3 step 3 specifies `toleranceBefore: .zero, toleranceAfter: .zero`. |
| AC-05.2: 3s GIF encode ≤5s on iPhone 13+ | ImageIO hardware path, batch frame processing | **PASS** | Arch Spec §8.2 maps this target to architecture support. |
| AC-08.4: StoreKit 2 subscriptions at $9.99/yr only | SubscriptionManager wrapping StoreKit 2 | **PASS** | Arch Spec §3.2 includes SubscriptionManager in the service layer. §3.3 lists StoreKit 2. |
| AC-10.3: Loading indicator uses compliant language (not "Downloading…") | CREATE GIF button progress ring (indeterminate during extraction, determinate during download). No loading text screen. | **PASS** | Supplemental Handoff §1.1 replaced text loading indicator with button progress ring. No "download" language anywhere in the UI. |

### 2.3 Non-Functional Requirements

| PRD NFR | Architecture Support | Status | Notes |
|---------|---------------------|--------|-------|
| iOS 17.0 minimum | Arch Spec §3.1 confirms iOS 17.0 deployment target | **PASS** | Aligned. |
| Memory ≤300 MB peak during encoding | Batch processing (20 frames per batch) in Arch Spec §8.3 | **PASS** | Calculated peak: ~54 MB frame data + GIF buffer overhead. Within budget. |
| Offline trim and export after import | Arch Spec §4.3–4.5 require no network calls after Phase 2 | **PASS** | Confirmed: Phases 3–5 are entirely on-device. |
| All strings in Localizable.strings | Arch Spec §3.5 + API Contract §7.2 reference Localizable.strings | **PASS** | Architecture supports localization readiness. |
| Accessibility: VoiceOver, Dynamic Type, 44pt touch targets | Not explicitly detailed in Architecture Spec | **FLAG** | See Gap #1 below. |

## 3. Hard Constraint Compliance

These are non-negotiable constraints from the feasibility report and system instructions. Every artifact must comply.

| Constraint | Brief | PRD | Arch Spec | API Contract | Status |
|------------|-------|-----|-----------|-------------|--------|
| No YouTube support in MVP | §5 Risk 1 | §3.3 exclusion | N/A (backend enforcement) | §5.6 explicit exclusion with error code | **PASS** |
| Never use "download" in user-facing language | §5 Risk 1 | AC-01.5 | N/A (client-side strings) | §4 all user-facing messages checked | **PASS** |
| Server-side yt-dlp only; never on iOS client | §5 Risk 1 | Implicit (architecture-level) | §1.2 explicit tier responsibilities | §3.1 server-only extraction | **PASS** |
| Swift/SwiftUI native (Path A) | N/A (feasibility §5.2) | Implicit | §3.1 confirms Swift 5.10+ / SwiftUI | N/A | **PASS** |
| Zero personal data collection | §5 Risk 1 | F-12, AC-12.1–12.5 | §3.5 (UserDefaults keys are non-personal), §7.5 | N/A | **PASS** |
| All documentation in Markdown | System instructions | All .md | All .md | All .md | **PASS** |
| YAML frontmatter on all documents | System instructions | Present | Present | Present | **PASS** |

## 4. Gap Identification

### Gap #1: Accessibility Architecture Detail

**Finding:** The PRD specifies accessibility requirements (§6.4): VoiceOver labels, VoiceOver support for trim handles with spoken positions, Dynamic Type for all text, 44×44pt minimum touch targets. The Architecture Spec does not include a dedicated section on how these requirements map to the architecture (e.g., which ViewModels expose accessibility state, how the trim handle ViewModel publishes position data for VoiceOver).

**Severity:** Low. SwiftUI has built-in accessibility support (`.accessibilityLabel()`, `.accessibilityValue()`, Dynamic Type scaling). The architecture does not need structural changes to support accessibility — it requires implementation attention during the Development phase.

**Resolution:** Add an accessibility annotation to each epic in the Epic Breakdown that touches UI components. The BMAD Scrum Master agent should include accessibility acceptance criteria in every story that involves a user-facing view. No architecture change required.

### Gap #2: Subscription Restoration Flow Detail

**Finding:** PRD AC-08.5 requires purchase restoration on new devices. The Architecture Spec lists `SubscriptionManager` as a service and references StoreKit 2, but does not detail the restoration flow (when does the app check for existing subscriptions? on every launch? on first export attempt?).

**Severity:** Low. StoreKit 2 handles transaction persistence and restoration natively. The `SubscriptionManager` wrapper needs to check `Transaction.currentEntitlements` on app launch to determine the user's subscription status.

**Resolution:** The Scrum Master should include a dedicated story within the Freemium & Subscriptions epic for subscription state initialization on launch and restoration behavior. The Developer agent will implement `Transaction.currentEntitlements` iteration in the `SubscriptionManager.init()` or a dedicated `refreshStatus()` method. No architecture change required.

### Gap #3: Instagram Authentication Handling

**Finding:** API Contract §5.2 notes that Instagram extraction "may require session cookies for some content." The Architecture Spec does not address how this is managed operationally (where is the cookie stored? how is it refreshed? what happens when it expires?).

**Severity:** Moderate. If Instagram requires authentication for most content, the extraction success rate for Instagram links could be unacceptably low without session cookies.

**Resolution:** The backend should support an optional Instagram session cookie configured as an environment variable (`INSTAGRAM_SESSION_COOKIE`). If present, yt-dlp is invoked with the `--cookies-from-browser` or `--cookies` flag pointing to a cookie file generated from this variable. The operational process for refreshing the cookie (manual, periodic) is a post-deployment concern. The API Contract already specifies a differentiated error message for Instagram failures ("The post may be private"), which covers the user-facing experience. Add a deployment note to the Architecture Spec's backend section documenting this configuration option. The Scrum Master should include Instagram cookie configuration as a story in the Backend API epic.

### Gap #4: Estimated File Size Calculation (Pre-Encoding) — RESOLVED (v2)

**Resolved by v2 design decision:** Quality presets have been removed entirely. The encoder uses a single ≤8 MB auto-optimized target with no user-facing settings screen. No file size estimation UI is needed.

## 5. Validation Summary

| Category | Items Checked | Pass | Flag | Conflict |
|----------|---------------|------|------|----------|
| Brief ↔ PRD alignment | 12 | 12 | 0 | 0 |
| PRD ↔ Architecture alignment | 21 | 20 | 1 | 0 |
| Hard constraint compliance | 7 | 7 | 0 | 0 |
| Gaps identified | 4 | — | 4 (1 resolved by v2) | 0 |

**Overall assessment: ALIGNED.** All three documents are consistent in their treatment of features, architecture, constraints, and risk mitigations. The four gaps identified are implementation-detail items that do not require changes to the architecture or PRD — they are resolved by adding specificity in the Epic Breakdown and Scrum Master stories. No conflicts were found between any pair of documents.

The planning phase documents are ready to proceed to Epic Breakdown and subsequently to the BMAD Development Phase (Scrum Master → Developer → QA).
