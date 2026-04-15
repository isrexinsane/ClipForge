---
title: "ClipForge — API Contract"
agent: Architect
phase: Planning
status: Complete
date: 2026-04-10
project: ClipForge
org: Ronin Art House
depends_on:
  - Architecture_Spec.md
  - PRD.md
---

# ClipForge — API Contract

This document is the formal contract between the ClipForge iOS client and the ClipForge backend API. Both sides must conform to the schemas and behaviors defined here. Any change to this contract requires a version bump and coordinated updates to both client and server.

## 1. Base URL and Versioning

**Base URL:** `https://api.clipforge.app/v1`

The API is versioned via URL path prefix (`/v1`, `/v2`, etc.). A new major version is created when breaking changes are introduced (removed fields, changed semantics). Additive changes (new optional fields, new endpoints) do not require a version bump.

The domain `api.clipforge.app` resolves to the VPS deployment. During development and TestFlight beta, a staging URL (`https://api-staging.clipforge.app/v1`) is used. The iOS client reads the base URL from a configuration file, making the switch between staging and production a build-time setting, not a code change.

## 2. Authentication

Every request must include an API key in the `X-API-Key` header. Requests without a valid key receive a `401 Unauthorized` response.

```
X-API-Key: cf_live_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

Key format: `cf_live_` prefix for production, `cf_staging_` prefix for staging. This prevents accidental cross-environment requests.

The API key is a shared secret embedded in the iOS binary. It authenticates the app, not individual users. There are no user accounts, no OAuth flows, and no per-user tokens in the MVP.

## 3. Endpoints

### 3.1 POST /v1/extract

Accepts a social media URL, extracts the video via yt-dlp, and returns the video data or a temporary URL to retrieve it.

This is the core endpoint. It is the only endpoint that invokes yt-dlp and performs meaningful work.

#### Request

**Method:** POST
**Path:** `/v1/extract`
**Content-Type:** `application/json`
**Headers:**
- `X-API-Key` (required): API key string

**Body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `url` | string | Yes | The social media URL to extract video from |
| `max_resolution` | string | No | Maximum video resolution. Values: `"480p"`, `"720p"`. Default: `"720p"`. The backend selects the best available stream at or below this resolution. |
| `max_duration` | integer | No | Maximum source video duration in seconds. If the source video exceeds this, the backend returns an error rather than extracting. Default: `60`. Maximum: `60`. |

```json
{
  "url": "https://x.com/user/status/1234567890",
  "max_resolution": "720p",
  "max_duration": 60
}
```

#### Response — Success (200 OK)

| Field | Type | Description |
|-------|------|-------------|
| `status` | string | Always `"success"` |
| `platform` | string | Identified platform: `"twitter"`, `"instagram"`, `"reddit"`, `"tiktok"`, `"twitch"` |
| `video_url` | string | Temporary signed URL to download the extracted video file. Valid for 5 minutes. |
| `duration` | float | Video duration in seconds |
| `width` | integer | Video width in pixels |
| `height` | integer | Video height in pixels |
| `file_size` | integer | Video file size in bytes |
| `content_type` | string | MIME type of the video file, typically `"video/mp4"` |
| `title` | string or null | Title/caption of the source post, if available. Not displayed to the user in MVP but useful for future features. |

```json
{
  "status": "success",
  "platform": "twitter",
  "video_url": "https://api.clipforge.app/v1/media/tmp_a1b2c3d4.mp4?token=eyJ...&expires=1712800000",
  "duration": 14.2,
  "width": 1280,
  "height": 720,
  "file_size": 4821504,
  "content_type": "video/mp4",
  "title": "Coach reaction after the missed call 😂"
}
```

#### Response — Error (4xx/5xx)

All error responses share this schema:

| Field | Type | Description |
|-------|------|-------------|
| `status` | string | Always `"error"` |
| `error_code` | string | Machine-readable error identifier (see §4) |
| `message` | string | Human-readable debug message (not for user display) |
| `retry_after` | integer or null | Seconds to wait before retrying, if applicable (rate limits, temporary failures) |

```json
{
  "status": "error",
  "error_code": "UNSUPPORTED_PLATFORM",
  "message": "The URL host 'youtube.com' is not in the supported platforms list.",
  "retry_after": null
}
```

#### Rate Limits

| Window | Limit | Scope |
|--------|-------|-------|
| Per minute | 10 requests | Per API key |
| Per hour | 60 requests | Per API key |
| Per day | 200 requests | Per API key |

Rate limit status is communicated via response headers on every request:

```
X-RateLimit-Limit: 10
X-RateLimit-Remaining: 7
X-RateLimit-Reset: 1712796120
```

When a rate limit is exceeded, the endpoint returns HTTP 429 with the standard error schema and a `retry_after` value.

### 3.2 GET /v1/media/{file_id}

Serves the extracted video file for download by the iOS client. This is the URL returned in the `video_url` field of the extract response.

#### Request

**Method:** GET
**Path:** `/v1/media/{file_id}`
**Query Parameters:**
- `token` (required): Signed token proving the request is authorized. Generated by the server and included in the `video_url`.
- `expires` (required): Unix timestamp after which the URL is no longer valid.

**No `X-API-Key` header required** — the signed token serves as authentication for this endpoint. This allows the URL to be consumed directly by `URLSession`'s download task without custom header injection.

#### Response — Success (200 OK)

**Content-Type:** `video/mp4` (or the actual content type of the extracted video)
**Body:** Raw video file data, streamed.

The response includes standard HTTP caching headers:
```
Content-Length: 4821504
Content-Disposition: attachment; filename="clip.mp4"
Cache-Control: no-store
```

#### Response — Error

| HTTP Status | error_code | Condition |
|-------------|-----------|-----------|
| 403 | `INVALID_TOKEN` | Token is malformed or signature doesn't match |
| 410 | `EXPIRED_MEDIA` | The 5-minute window has passed; file has been cleaned up |
| 404 | `MEDIA_NOT_FOUND` | File ID doesn't exist (already cleaned up or never created) |

### 3.3 GET /v1/health

A lightweight health check endpoint for monitoring. Returns the server status and the installed yt-dlp version (useful for confirming updates deployed correctly).

#### Request

**Method:** GET
**Path:** `/v1/health`
**No authentication required.**

#### Response — Success (200 OK)

```json
{
  "status": "healthy",
  "yt_dlp_version": "2026.04.07",
  "supported_platforms": ["twitter", "instagram", "reddit", "tiktok", "twitch"],
  "uptime_seconds": 86412
}
```

## 4. Error Code Reference

This table defines every error code the API can return. The iOS client maps each `error_code` to a user-facing string in `Localizable.strings`. The `message` field in the error response is for developer debugging and is never shown to users.

| error_code | HTTP Status | Meaning | iOS User-Facing Message |
|------------|-------------|---------|------------------------|
| `UNSUPPORTED_PLATFORM` | 400 | URL host is not in the supported platforms list | "This link isn't supported yet. ClipForge works with Twitter/X, Instagram, Reddit, TikTok, and Twitch." |
| `INVALID_URL` | 400 | URL is malformed or doesn't match expected patterns for any supported platform | "That doesn't look like a valid link. Copy the full URL from the app and try again." |
| `VIDEO_TOO_LONG` | 400 | Source video exceeds `max_duration` | "This video is too long. ClipForge works with clips up to 60 seconds." |
| `EXTRACTION_FAILED` | 502 | yt-dlp failed to extract the video (platform change, private content, deleted post) | "We couldn't get the video from this link. The post may be private, deleted, or the platform may have changed something." |
| `EXTRACTION_TIMEOUT` | 504 | yt-dlp did not complete within 30 seconds | "This is taking too long. Try again — it usually works on the second attempt." |
| `PLATFORM_UNAVAILABLE` | 503 | yt-dlp extractor for this platform is known to be broken (manually flagged) | "We can't get videos from [Platform] right now. This usually fixes itself quickly." |
| `RATE_LIMITED` | 429 | Request exceeds rate limits | "You're creating GIFs faster than we can keep up! Try again in a moment." |
| `UNAUTHORIZED` | 401 | Missing or invalid API key | "Something went wrong. Please update ClipForge to the latest version." |
| `SERVER_ERROR` | 500 | Unhandled server exception | "Something went wrong on our end. Try again in a moment." |
| `INVALID_TOKEN` | 403 | Media download token is invalid | "The video link has expired. Import the video again." |
| `EXPIRED_MEDIA` | 410 | Media file has expired (past 5-minute window) | "The video link has expired. Import the video again." |
| `MEDIA_NOT_FOUND` | 404 | Media file does not exist | "The video link has expired. Import the video again." |

## 5. Supported Platform URL Patterns

The backend validates incoming URLs against these patterns before invoking yt-dlp. The iOS client uses the same patterns for clipboard detection. Both implementations must stay in sync — any platform addition or pattern change must be reflected in both the backend validator and the iOS `SupportedPlatforms` configuration.

### 5.1 Twitter/X

| Pattern | Example |
|---------|---------|
| `https://twitter.com/{user}/status/{id}` | `https://twitter.com/NBA/status/1234567890` |
| `https://x.com/{user}/status/{id}` | `https://x.com/NBA/status/1234567890` |
| `https://mobile.twitter.com/{user}/status/{id}` | `https://mobile.twitter.com/NBA/status/1234567890` |
| `https://t.co/{shortcode}` | `https://t.co/abc123` (redirects resolved server-side) |

### 5.2 Instagram

| Pattern | Example |
|---------|---------|
| `https://www.instagram.com/reel/{id}/` | `https://www.instagram.com/reel/CxYz123/` |
| `https://www.instagram.com/p/{id}/` | `https://www.instagram.com/p/CxYz123/` |
| `https://instagram.com/reel/{id}/` | (without www) |
| `https://www.instagram.com/stories/{user}/{id}/` | Story clips |

**Note:** Instagram extraction may require session cookies for some content. The backend should support an optional Instagram session cookie configured as an environment variable. If extraction fails without authentication, the error should indicate the content may be private rather than giving a generic failure.

### 5.3 Reddit

| Pattern | Example |
|---------|---------|
| `https://www.reddit.com/r/{sub}/comments/{id}/{slug}/` | Full post URL |
| `https://reddit.com/r/{sub}/comments/{id}/{slug}/` | (without www) |
| `https://v.redd.it/{id}` | Direct video link |
| `https://old.reddit.com/r/{sub}/comments/{id}/{slug}/` | Old Reddit URL |

### 5.4 TikTok

| Pattern | Example |
|---------|---------|
| `https://www.tiktok.com/@{user}/video/{id}` | Full video URL |
| `https://vm.tiktok.com/{shortcode}` | Short share link |
| `https://www.tiktok.com/t/{shortcode}/` | Alternative short link |

### 5.5 Twitch

| Pattern | Example |
|---------|---------|
| `https://clips.twitch.tv/{slug}` | Twitch clip |
| `https://www.twitch.tv/{channel}/clip/{slug}` | Alternative clip URL |

### 5.6 Explicitly Excluded

| Platform | Reason |
|----------|--------|
| YouTube (youtube.com, youtu.be, m.youtube.com) | App Store rejection risk — hard exclusion per feasibility report |
| Facebook (facebook.com, fb.watch) | Complex authentication requirements; deferred to post-MVP |
| Snapchat | No public video URLs; not extractable |

If a user submits a YouTube URL, the backend returns `UNSUPPORTED_PLATFORM` and the iOS client shows: "YouTube isn't supported to keep ClipForge available on the App Store. Try a link from Twitter/X, Instagram, Reddit, TikTok, or Twitch."

## 6. Request/Response Examples

### 6.1 Successful Twitter/X Extraction

**Request:**
```http
POST /v1/extract HTTP/1.1
Host: api.clipforge.app
Content-Type: application/json
X-API-Key: cf_live_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

{
  "url": "https://x.com/NBA/status/1234567890123456789",
  "max_resolution": "720p",
  "max_duration": 60
}
```

**Response (200 OK):**
```http
HTTP/1.1 200 OK
Content-Type: application/json
X-RateLimit-Limit: 10
X-RateLimit-Remaining: 8
X-RateLimit-Reset: 1712796120

{
  "status": "success",
  "platform": "twitter",
  "video_url": "https://api.clipforge.app/v1/media/tmp_a1b2c3d4.mp4?token=eyJhbGciOiJIUzI1NiJ9...&expires=1712796600",
  "duration": 14.2,
  "width": 1280,
  "height": 720,
  "file_size": 4821504,
  "content_type": "video/mp4",
  "title": "Coach reaction after the missed call 😂"
}
```

### 6.2 Unsupported Platform (YouTube)

**Request:**
```http
POST /v1/extract HTTP/1.1
Host: api.clipforge.app
Content-Type: application/json
X-API-Key: cf_live_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

{
  "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
}
```

**Response (400 Bad Request):**
```json
{
  "status": "error",
  "error_code": "UNSUPPORTED_PLATFORM",
  "message": "The URL host 'www.youtube.com' is not in the supported platforms list.",
  "retry_after": null
}
```

### 6.3 Extraction Failure (Deleted Post)

**Request:**
```http
POST /v1/extract HTTP/1.1
Host: api.clipforge.app
Content-Type: application/json
X-API-Key: cf_live_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

{
  "url": "https://x.com/user/status/9999999999999999999"
}
```

**Response (502 Bad Gateway):**
```json
{
  "status": "error",
  "error_code": "EXTRACTION_FAILED",
  "message": "yt-dlp returned exit code 1: Unable to extract video data. The content may have been deleted.",
  "retry_after": null
}
```

### 6.4 Rate Limited

**Response (429 Too Many Requests):**
```json
{
  "status": "error",
  "error_code": "RATE_LIMITED",
  "message": "Per-minute rate limit exceeded (10/min). Client has made 11 requests in the current window.",
  "retry_after": 23
}
```

### 6.5 Health Check

**Request:**
```http
GET /v1/health HTTP/1.1
Host: api.clipforge.app
```

**Response (200 OK):**
```json
{
  "status": "healthy",
  "yt_dlp_version": "2026.04.07",
  "supported_platforms": ["twitter", "instagram", "reddit", "tiktok", "twitch"],
  "uptime_seconds": 86412
}
```

## 7. iOS Client Implementation Notes

These notes guide the BMAD Developer agent when implementing the networking layer in Swift.

### 7.1 APIService Structure

The `APIService` class (or struct with static methods) wraps `URLSession` and provides two methods: `extractVideo(url:)` and `downloadMedia(from:)`. The first calls `POST /v1/extract` and returns a decoded `ExtractionResponse` model. The second takes the `video_url` from the response and downloads the video file to the app's `Caches` directory, returning a local file URL.

Both methods are `async throws` functions, using Swift's structured concurrency. Errors are typed to a `ClipForgeAPIError` enum that maps to the `error_code` values in this contract.

### 7.2 Error Mapping

```swift
enum ClipForgeAPIError: Error {
    case unsupportedPlatform
    case invalidURL
    case videoTooLong
    case extractionFailed
    case extractionTimeout
    case platformUnavailable
    case rateLimited(retryAfter: Int)
    case unauthorized
    case serverError
    case invalidToken
    case expiredMedia
    case mediaNotFound
    case networkUnavailable
    case unknown(statusCode: Int, message: String)
}
```

Each case maps to the user-facing strings in `Localizable.strings`. The ViewModel layer does this mapping; the APIService layer throws the typed error.

### 7.3 Retry Logic

The `extractVideo` method implements the retry strategy defined in the Architecture Spec (§8.4): up to 2 retries with exponential backoff (2s, 4s) for transient errors (`EXTRACTION_TIMEOUT`, `SERVER_ERROR`, `networkUnavailable`). Non-transient errors (`UNSUPPORTED_PLATFORM`, `INVALID_URL`, `VIDEO_TOO_LONG`) are not retried.

Rate limit errors (`RATE_LIMITED`) are not retried automatically. The `retryAfter` value is surfaced to the UI layer, which shows a countdown or a "try again later" message.
