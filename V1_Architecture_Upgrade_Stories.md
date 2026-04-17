---
title: "ClipForge — V1 Architecture Upgrade Stories"
type: epic-stories
agent: SM
date: 2026-04-16
status: APPROVED
priority: CRITICAL — v1.0 requirements
depends_on:
  - CLAUDE.md
  - Architecture_Spec.md
  - API_Contract.md
  - Master_Session_Handoff_2026-04-16.md
---

# V1 Architecture Upgrade Stories

> These two features transform the app from "functional prototype" to "production-quality competitor." Both are v1.0 requirements, not post-launch.

---

## Epic 13: Managed Extraction API (Instagram Speed + Cookie Elimination)

### Problem Statement

The current architecture uses yt-dlp on our Railway backend to extract video from Instagram. This creates three compounding problems:

1. **Speed:** Instagram serves HEVC video. Our backend must download it, then ffmpeg-transcode to H.264 for iOS compatibility. This takes 30-90 seconds per request — unacceptable for a product that promises speed as its core value.

2. **Cookie dependency:** Instagram requires authenticated session cookies to serve video content. These cookies expire every few weeks, requiring manual refresh (export from Chrome → paste into Railway environment variables). This is untenable for production.

3. **Reliability:** Even with fresh cookies and residential proxies, Instagram extraction fails intermittently. yt-dlp's Instagram extractor is community-maintained and breaks whenever Instagram changes their frontend.

### Solution

Replace yt-dlp for Instagram with a **managed extraction/scraper API service** that handles proxies, authentication, and anti-bot measures internally. The app sends a URL, receives a direct CDN video URL in 3-5 seconds. No transcoding, no cookies, no proxy management.

**Recommended service candidates (evaluate in order):**

1. **ScrapingBee** — 99.65% Instagram success rate, ~4.5s average response time, free trial with 1,000 credits. Simple REST API.
2. **Thordata Instagram Scraper API** — Purpose-built for Instagram, includes video extraction endpoints.
3. **RapidAPI Instagram scrapers** — Multiple providers, pay-per-request, varying quality.

**Keep yt-dlp for:** Twitter/X and Twitch, where it works reliably without cookies or transcoding.

### Architecture Change

```
CURRENT (slow):
App → Our Backend → yt-dlp (fetch HEVC) → ffmpeg (transcode H.264) → serve to app
                     ↑ requires cookies, proxy, 30-90 seconds

NEW (fast):
App → Our Backend → Managed API (returns CDN URL) → app downloads directly from CDN
                     ↑ no cookies, no proxy, no transcode, 3-5 seconds
```

The backend becomes a thin routing layer:
- Instagram URL detected → call managed API → return CDN video URL to app
- Twitter/X URL detected → call yt-dlp (existing flow) → return video URL to app  
- Twitch URL detected → call yt-dlp (existing flow) → return video URL to app

---

### STORY-13.1: Evaluate and Select Managed Extraction API

**As a** developer,
**I want to** evaluate managed Instagram extraction APIs and select one,
**So that** I have a concrete integration target for the speed upgrade.

**Acceptance Criteria:**
- [ ] Test at least 2 managed API services with 5+ Instagram Reel URLs each
- [ ] Measure average response time (target: <5 seconds)
- [ ] Measure success rate (target: >95%)
- [ ] Confirm the API returns a direct video URL (not raw video bytes)
- [ ] Confirm the video URL serves H.264 MP4 (playable by AVPlayer without transcoding)
- [ ] Document pricing model (per-request, monthly, bandwidth-based)
- [ ] Document API contract (endpoint, auth, request format, response format)
- [ ] Select the winner and document the rationale

**Implementation Notes:**
- ScrapingBee offers a free 1,000 credit trial — start there
- Test with the same Reel URLs that failed/were slow with yt-dlp
- The video URL returned must be a direct MP4 link, not an HTML page or embed
- Some APIs return metadata only (profile info, likes) — we need the actual video file URL

---

### STORY-13.2: Backend Routing Layer — Instagram via Managed API

**As a** user importing an Instagram video,
**I want** the extraction to complete in under 5 seconds,
**So that** the app feels instant and I don't lose my meme moment.

**Acceptance Criteria:**
- [ ] Backend detects Instagram URLs and routes to the managed API instead of yt-dlp
- [ ] Backend sends the Instagram URL to the managed API with proper authentication
- [ ] Backend receives the direct video CDN URL from the managed API
- [ ] Backend returns the CDN URL to the iOS app in the same ExtractionResponse format
- [ ] Twitter/X and Twitch URLs continue to use yt-dlp (no change)
- [ ] Average Instagram extraction time is <5 seconds (measured via backend logs)
- [ ] No Instagram cookies required — the managed API handles authentication
- [ ] No ffmpeg transcoding required — the CDN serves H.264 natively
- [ ] Error handling: if managed API fails, return a clear error (not a generic 502)
- [ ] Environment variable for managed API key (same pattern as CLIPFORGE_API_KEY)

**Implementation Notes:**
- New file: `backend/app/extractors/instagram_api.py` (or similar)
- Modify `extraction.py` to route based on platform: Instagram → managed API, others → yt-dlp
- The managed API key goes in Railway environment variables
- Remove Instagram-specific yt-dlp code (codec args, timeout, cookie handling)
- Keep the `/v1/extract` endpoint interface identical — the iOS app doesn't need to change

---

### STORY-13.3: Remove Instagram Cookie Infrastructure

**As a** developer/operator,
**I want to** remove all Instagram cookie management from the backend,
**So that** the app requires zero manual maintenance for Instagram extraction.

**Acceptance Criteria:**
- [ ] Remove `YTDLP_COOKIES_CONTENT` environment variable from Railway (or make it optional for other platforms)
- [ ] Remove Instagram-specific cookie handling from extraction.py
- [ ] Remove Instagram H.264 transcoding arguments (no longer needed with direct CDN URL)
- [ ] Update CLAUDE.md to reflect the new architecture
- [ ] Update API_Contract.md if response format changes
- [ ] Document the managed API service, its pricing, and how to rotate the API key

---

### STORY-13.4: iOS App — Handle Direct CDN Video URLs

**As a** user,
**I want** the video to start playing immediately after extraction,
**So that** I can begin trimming without waiting for a slow server transfer.

**Acceptance Criteria:**
- [ ] When the backend returns an absolute CDN URL (https://...instagram...cdn...mp4), the app downloads directly from the CDN instead of from our backend's /v1/media/ proxy
- [ ] Progress ring shows accurate download progress from the CDN
- [ ] Video plays immediately in the trim modal (H.264, no codec issues)
- [ ] If the CDN URL expires or 404s, show a retry error (not a crash)
- [ ] Existing relative URL handling (for Twitter/X via our backend proxy) still works

**Implementation Notes:**
- HomeViewModel already handles both absolute and relative video URLs
- The change is that Instagram will now return absolute CDN URLs instead of relative /v1/media/ paths
- May need to handle Instagram CDN-specific headers or redirects
- Test with multiple Reels to confirm codec compatibility

---

## Epic 14: iOS Share Extension (Clipboard Bypass)

### Problem Statement

The current flow requires users to copy a link from a social media app, then switch to ClipForge, where clipboard detection reads the URL. This fails intermittently because:

1. iOS sometimes clears the clipboard during app switches for privacy
2. The paste permission dialog introduces friction
3. Clipboard monitoring only fires on specific lifecycle events, missing some pastes

Apps like Seal solve this with a Share Extension — the user taps "Share" in Instagram/Twitter and sees ClipForge in the share sheet. The link goes directly to the app with zero clipboard involvement.

### Solution

Build an **iOS Share Extension** that accepts URL types. When a user taps Share in any social media app → selects ClipForge → the extension receives the URL and either:
- Opens the main app with the URL pre-loaded (deeplink)
- Processes the URL directly within the extension (limited by iOS extension memory limits)

The recommended approach is Option A (deeplink to main app) because the video extraction, trimming, and GIF encoding all require more resources than an extension allows.

### Architecture

```
USER FLOW:
Instagram → Share button → [ClipForge] in share sheet → app opens with URL pre-loaded → CREATE GIF

TECHNICAL FLOW:
Share Extension receives URL → extracts URL string → opens main app via URL scheme or App Group → main app reads URL from shared container → proceeds with normal import flow
```

---

### STORY-14.1: Create Share Extension Target in Xcode

**As a** developer,
**I want to** add a Share Extension target to the ClipForge Xcode project,
**So that** the app appears in the iOS share sheet for URL content.

**Acceptance Criteria:**
- [ ] New target: "ClipForgeShareExtension" in the Xcode project
- [ ] Extension declares it accepts URLs (UTType: public.url)
- [ ] Extension appears in the iOS share sheet when sharing a URL from Safari, Twitter, Instagram
- [ ] Extension has the same app icon as the main app
- [ ] Extension is signed with the same team and provisioning profile
- [ ] App Group created: "group.com.roninart.clipforge" for shared data between extension and main app

**Implementation Notes:**
- File → New → Target → Share Extension
- The extension's Info.plist needs NSExtensionActivationRule configured to accept URLs
- The App Group must be added to both the main app and the extension in Signing & Capabilities
- The extension's bundle ID must be a child of the main app: com.roninart.clipforge.share-extension

---

### STORY-14.2: Share Extension UI and URL Extraction

**As a** user sharing a link from Instagram,
**I want** to tap ClipForge in the share sheet and have the app open with my link ready,
**So that** I can create a GIF without copying/pasting anything.

**Acceptance Criteria:**
- [ ] Share Extension receives the shared URL from the host app
- [ ] Extension extracts the URL string from the NSExtensionItem
- [ ] Extension validates the URL against SupportedPlatform patterns
- [ ] If URL is supported: writes URL to App Group shared UserDefaults, then opens main app via custom URL scheme (e.g., clipforge://import?url=...)
- [ ] If URL is not supported: shows a brief error message in the extension ("This link isn't supported yet") and dismisses
- [ ] Extension UI is minimal — just a brief "Opening ClipForge..." message, no complex views
- [ ] Extension dismisses automatically after handing off to the main app

**Implementation Notes:**
- Use `extensionContext?.completeRequest(returningItems: nil)` to dismiss
- Open main app via: `openURL(URL(string: "clipforge://import?url=\(encodedURL)")!)`
- Note: Share Extensions can't call `UIApplication.shared.open()` directly — use the `openURL:` method on the extension context, or write to App Group and let the main app check on foreground
- Alternative approach: write URL to App Group UserDefaults, then use `NSUserActivity` handoff

---

### STORY-14.3: Main App — Handle Incoming URLs from Share Extension

**As a** developer,
**I want** the main app to receive URLs from the Share Extension and start the import flow automatically,
**So that** the share-to-GIF experience is seamless.

**Acceptance Criteria:**
- [ ] Main app registers custom URL scheme: "clipforge" in Info.plist
- [ ] ClipForgeApp.swift handles `.onOpenURL { url in ... }` to receive incoming URLs
- [ ] When a URL arrives via the scheme, the app extracts the social media URL from the query parameter
- [ ] The extracted URL is passed to HomeViewModel to start the import flow automatically (same as clipboard detection, but skips the paste permission dialog)
- [ ] If the app was not running, it launches and processes the URL on first load
- [ ] If the app was backgrounded, it foregrounds and processes the URL
- [ ] The import starts immediately — no additional tap required (unlike clipboard flow where user taps CREATE GIF)
- [ ] Supported platform detection works correctly for URLs received via share extension
- [ ] Unsupported URLs (YouTube, etc.) show the appropriate rejection message

**Implementation Notes:**
- In ClipForgeApp.swift: `.onOpenURL { url in handleIncomingURL(url) }`
- Parse: `clipforge://import?url=https%3A%2F%2Fwww.instagram.com%2Freel%2F...`
- URL-decode the parameter, validate against SupportedPlatform, pass to HomeViewModel
- Consider adding a brief "Importing from Instagram..." state to give the user context

---

### STORY-14.4: Aggressive Clipboard Polling (Interim Fix)

**As a** user who copies a link and switches to ClipForge,
**I want** the app to detect the link reliably every time,
**So that** I don't have to retry or use workarounds.

**Acceptance Criteria:**
- [ ] When the app comes to the foreground, check the clipboard immediately
- [ ] Continue checking every 0.5 seconds for 3 seconds after foregrounding (6 total checks)
- [ ] Stop polling after a URL is detected or after the 3-second window
- [ ] Each check respects the iOS paste permission dialog — only check UIPasteboard after permission is granted
- [ ] If a URL is detected during polling, update the UI state (same as current clipboard detection)
- [ ] Polling does not run when the app is in the background (battery preservation)
- [ ] This is an interim fix that remains active even after the Share Extension ships (belt and suspenders)

**Implementation Notes:**
- Modify ClipboardMonitor.swift
- Use a Timer that fires every 0.5s, started on `scenePhase == .active`
- Cancel the timer after 3 seconds or on URL detection
- The current `scenePhase` observer only fires once on foreground — the timer adds resilience

---

## Implementation Priority

| Story | Priority | Dependencies | Estimated Sessions |
|-------|----------|-------------|-------------------|
| STORY-14.4 (Clipboard polling) | DO FIRST | None | 1 session |
| STORY-13.1 (Evaluate APIs) | HIGH | None (research) | 1 session |
| STORY-13.2 (Backend routing) | HIGH | 13.1 | 1-2 sessions |
| STORY-13.3 (Remove cookies) | HIGH | 13.2 | Same session as 13.2 |
| STORY-13.4 (iOS CDN URLs) | HIGH | 13.2 | 1 session |
| STORY-14.1 (Extension target) | HIGH | None | 1 session |
| STORY-14.2 (Extension UI) | HIGH | 14.1 | 1 session |
| STORY-14.3 (Main app handler) | HIGH | 14.2 | 1 session |

**Total estimated: 6-8 Cowork sessions across 2-3 days.**

The clipboard polling fix (STORY-14.4) should be done immediately — it's a 1-session fix that improves reliability for the current flow while the Share Extension is being built.
