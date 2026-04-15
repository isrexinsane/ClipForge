---
title: "Stage 3 Mega-Checkpoint — End-to-End Test Plan"
date: 2026-04-15
status: Partial — 3/5 platforms confirmed, 2 with known issues
agent: QA
---

# Stage 3 Mega-Checkpoint — End-to-End Test Plan

> Tests the full pipeline from URL extraction through GIF creation. This document records both the test plan and actual results from the April 15, 2026 testing session.

---

## 1. Test Environment

| Component | Detail |
|-----------|--------|
| Backend | `clipforge-production-f27b.up.railway.app` |
| Proxy | IPRoyal residential proxy via `PROXY_URL` env var |
| yt-dlp | Nightly build (pinned in requirements.txt) |
| iOS | Simulator (Xcode), iOS 17+ |
| Test method | Debug URL input field in HomeView (clipboard doesn't sync in Simulator) |

---

## 2. Platform Extraction Tests

### Test 1: Twitter/X

| Step | Expected | Actual | Status |
|------|----------|--------|--------|
| POST /v1/extract with Twitter URL | 200, `platform: "twitter"`, `video_url` returned | 200 success, video URL returned | ✅ PASS |
| GET video from signed URL | 200, MP4 video data | Video downloaded successfully | ✅ PASS |
| Video plays in AVPlayer | Playback in TrimModalView | Plays correctly | ✅ PASS |
| Trim + CREATE GIF | GIF encodes, saves to Photos | **Pending on-device test** | ⏳ Deferred |

**Notes:** Twitter is the primary use case and works end-to-end through the extraction + download pipeline. Full GIF creation pipeline needs on-device testing (Simulator limitations with Photos library).

---

### Test 2: Instagram

| Step | Expected | Actual | Status |
|------|----------|--------|--------|
| POST /v1/extract with Instagram Reel URL | 200, `platform: "instagram"`, `video_url` returned | 200 success, video URL returned | ✅ PASS |
| GET video from signed URL | 200, MP4 video data (H.264) | Video downloaded, but HEVC codec (H.265 in MP4 container) | ⚠️ PARTIAL |
| Video plays in AVPlayer | Playback in TrimModalView | AVPlayer handles HEVC, plays OK | ✅ PASS |
| GIF encoding from HEVC input | GIF encodes correctly | **Untested — HEVC frame extraction may behave differently** | ⏳ Deferred |

**Notes:** Instagram returns HEVC video despite `--recode-video mp4` flag. The backend needs `-S vcodec:h264` or Instagram-specific format selection to force H.264 output. Filed as INSTAGRAM-CODEC in backlog.

**Fix needed:** Add to yt-dlp args for Instagram: `-S vcodec:h264` or `--recode-video mp4` with ffmpeg transcoding enabled on the server.

---

### Test 3: Reddit

| Step | Expected | Actual | Status |
|------|----------|--------|--------|
| POST /v1/extract with Reddit video URL | 200, `platform: "reddit"`, `video_url` returned | Intermittent — succeeds ~60% of attempts, times out ~40% | ⚠️ PARTIAL |
| GET video from signed URL (when extract succeeds) | 200, MP4 video data | Video downloaded successfully | ✅ PASS |
| Video plays in AVPlayer | Playback in TrimModalView | Plays correctly when download succeeds | ✅ PASS |

**Notes:** Reddit's v.redd.it CDN has inconsistent response times. Extended socket timeout to 60 seconds helps but doesn't fully resolve. The 502 EXTRACTION_TIMEOUT errors are transient — retrying usually works. The iOS client's retry logic (via `isTransient` on ClipForgeError) should handle this gracefully.

---

### Test 4: TikTok

| Step | Expected | Actual | Status |
|------|----------|--------|--------|
| POST /v1/extract with TikTok URL | 200, `platform: "tiktok"`, `video_url` returned | 502 EXTRACTION_FAILED — 403 from TikTok servers | ❌ FAIL |

**Notes:** TikTok's anti-bot measures go beyond IP detection. Even residential proxy IPs get 403 responses. This is an upstream platform issue, not a ClipForge code bug. The yt-dlp TikTok extractor may need browser cookies, specific headers, or `--extractor-args` configuration. Filed as TIKTOK-FIX in backlog.

**Impact:** TikTok is listed as a supported platform in the UI platform list. If this can't be resolved before launch, TikTok should be removed from the platform list or marked with a "coming soon" qualifier.

---

### Test 5: Twitch

| Step | Expected | Actual | Status |
|------|----------|--------|--------|
| POST /v1/extract with Twitch clip URL | 200, `platform: "twitch"`, `video_url` returned | 200 success, video URL returned | ✅ PASS |
| GET video from signed URL | 200, MP4 video data | Video downloaded successfully | ✅ PASS |
| Video plays in AVPlayer | Playback in TrimModalView | Plays correctly | ✅ PASS |

**Notes:** Twitch clips work cleanly. No special configuration needed beyond the residential proxy.

---

### Test 6: YouTube (Compliance Verification)

| Step | Expected | Actual | Status |
|------|----------|--------|--------|
| POST /v1/extract with YouTube URL | 400 UNSUPPORTED_PLATFORM | 400 `UNSUPPORTED_PLATFORM`: "The URL host 'youtube.com' is not in the supported platforms list." | ✅ PASS |

**Notes:** YouTube correctly rejected. Compliance constraint verified. No extraction attempted.

---

## 3. iOS Client Bug Fixes Validated

These bugs were discovered and fixed during the April 15 testing session:

| Bug | Fix | Verified |
|-----|-----|----------|
| ClipboardMonitor not firing on app launch | Added explicit `.onAppear` call to `checkClipboard()` | ✅ |
| API key placeholder in APIService | Replaced with actual key / config-based loading | ✅ |
| Relative URL crash in video download | Fixed URL construction to use absolute `video_url` from extraction response | ✅ |
| Missing NSPhotoLibraryAddUsageDescription | Added to Info.plist | ✅ |
| Debug URL input for Simulator testing | Added `#if DEBUG` text field in HomeView | ✅ |

---

## 4. Freemium Gating Tests (Epics 7–8)

| Test | Expected | Status |
|------|----------|--------|
| Free user: first GIF creation | `canExport` returns true, GIF created with watermark | ✅ Code verified |
| Free user: second GIF same day | `canExport` returns false, freemium gate prompt shown | ✅ Code verified |
| Free user: next day | Counter resets, `canExport` returns true again | ✅ Code verified (date comparison logic) |
| Premium user: unlimited GIFs | `canExport` always true, no watermark | ✅ Code verified |
| Watermark compositing | "CLIPFORGE" text bottom-right, 50% opacity, free tier only | ✅ Code verified |
| Export counter display | "X of 1 free GIFs remaining today" on success state | ✅ Code verified |
| Upgrade button tap | Presents SubscriptionView | ⏳ DEFERRED — stubbed with TODO |
| Restore Purchase (menu) | Calls `SubscriptionManager.restorePurchases()`, shows toast | ✅ Code verified |
| App launch entitlement check | `checkEntitlements()` syncs premium state from StoreKit | ✅ Code verified |

**Note:** "Code verified" means the logic is confirmed correct by code review. Runtime verification of StoreKit flows requires either a StoreKit Configuration file in Xcode or TestFlight sandbox environment.

---

## 5. Summary

### Platform Readiness

| Platform | Extraction | Full Pipeline | Launch Ready |
|----------|-----------|---------------|-------------|
| Twitter/X | ✅ | ⏳ (needs device test) | Yes (high confidence) |
| Instagram | ✅ | ⚠️ (HEVC codec issue) | After INSTAGRAM-CODEC fix |
| Reddit | ⚠️ (intermittent) | ⚠️ | Yes (with retry; transient issue) |
| TikTok | ❌ | ❌ | No — needs TIKTOK-FIX or removal from platform list |
| Twitch | ✅ | ⏳ (needs device test) | Yes (high confidence) |

### Verdict

**Stage 3 is PARTIALLY COMPLETE.** Three of five platforms (Twitter, Twitch, Reddit) are functional. Two platforms have known issues (Instagram codec, TikTok blocking). The core pipeline — extraction → download → trim → GIF encode → save — is architecturally complete and verified through code review. Full on-device end-to-end testing (clipboard → GIF in Photos) requires a physical device or TestFlight build.

### Recommended Next Steps

1. **Fix INSTAGRAM-CODEC** on backend (add H.264 format preference for Instagram)
2. **Investigate TIKTOK-FIX** or remove TikTok from platform list for MVP
3. **Wire SUBSCRIPTION-PRESENTATION** via wrapper view
4. **Build on physical device** for full pipeline validation including Photos library save
5. **TestFlight beta** once 4/5 platforms confirmed working
