"""
URL validation and platform detection for ClipForge.

Implements the input validation layer from Architecture Spec §7.2.
Every URL passes through validate_url() before reaching yt-dlp.
This is the primary security control preventing yt-dlp from being
used as a general-purpose content fetcher.
"""

import re
from urllib.parse import parse_qs, urlencode, urlparse, urlunparse

from pydantic import BaseModel

from app.validators.exceptions import (
    InvalidContentPathError,
    InvalidURLError,
    UnsupportedPlatformError,
)


class ValidatedURL(BaseModel):
    """Result of successful URL validation."""

    url: str  # Cleaned/sanitized URL
    platform: str  # Detected platform name (e.g., "twitter")
    original_url: str  # The URL as submitted


# ---------------------------------------------------------------------------
# Platform configuration
# ---------------------------------------------------------------------------

# Maps hostnames to platform names. Order doesn't matter — lookup is O(1).
_HOST_TO_PLATFORM: dict[str, str] = {
    # Twitter / X
    "twitter.com": "twitter",
    "www.twitter.com": "twitter",
    "x.com": "twitter",
    "www.x.com": "twitter",
    "mobile.twitter.com": "twitter",
    "mobile.x.com": "twitter",
    # Instagram
    "instagram.com": "instagram",
    "www.instagram.com": "instagram",
    # Reddit
    "reddit.com": "reddit",
    "www.reddit.com": "reddit",
    "old.reddit.com": "reddit",
    "v.redd.it": "reddit",
    # TikTok
    "tiktok.com": "tiktok",
    "www.tiktok.com": "tiktok",
    "vm.tiktok.com": "tiktok",
    # Twitch
    "twitch.tv": "twitch",
    "www.twitch.tv": "twitch",
    "clips.twitch.tv": "twitch",
}

# YouTube domains — explicitly rejected with a distinct error.
_YOUTUBE_HOSTS: set[str] = {
    "youtube.com",
    "www.youtube.com",
    "m.youtube.com",
    "youtu.be",
}

# Tracking parameters to strip from all URLs.
_TRACKING_PARAMS: set[str] = {
    "utm_source",
    "utm_medium",
    "utm_campaign",
    "utm_content",
    "utm_term",
    "ref",
    "ref_src",
    "s",
    "t",
}

# ---------------------------------------------------------------------------
# Path patterns per platform
# ---------------------------------------------------------------------------
# Each pattern must match the path component of a video content URL.
# Non-video pages (profiles, search, home feeds) are rejected.

_PATH_PATTERNS: dict[str, list[re.Pattern[str]]] = {
    # Twitter/X: /username/status/1234567890
    "twitter": [
        re.compile(r"^/[^/]+/status/\d+"),
    ],
    # Instagram: /reel/ABC123 or /p/ABC123
    "instagram": [
        re.compile(r"^/reel/[^/]+"),
        re.compile(r"^/p/[^/]+"),
    ],
    # Reddit: any path containing /comments/ — v.redd.it links bypass path check
    "reddit": [
        re.compile(r"/comments/"),
    ],
    # TikTok: /@username/video/1234567890 — vm.tiktok.com short links bypass path check
    "tiktok": [
        re.compile(r"^/@[^/]+/video/\d+"),
    ],
    # Twitch: /channel/clip/slug — clips.twitch.tv links bypass path check
    "twitch": [
        re.compile(r"^/[^/]+/clip/[^/]+"),
    ],
}

# Hosts where path validation is skipped (short links, direct video hosts).
_PATH_BYPASS_HOSTS: set[str] = {
    "v.redd.it",
    "vm.tiktok.com",
    "clips.twitch.tv",
}


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


def validate_url(url: str) -> ValidatedURL:
    """Validate and sanitize a URL for video extraction.

    Checks that the URL is well-formed, belongs to a supported platform,
    and has a path pattern consistent with video content. Strips tracking
    query parameters.

    Args:
        url: The raw URL string submitted by the client.

    Returns:
        A ValidatedURL with the cleaned URL, platform name, and original URL.

    Raises:
        InvalidURLError: The input is not a valid URL.
        UnsupportedPlatformError: The host is not in the allowlist.
        InvalidContentPathError: The host is allowed but the path is not
            a recognized video content pattern.
    """
    original_url = url.strip()

    # --- Structural validation ---
    parsed = urlparse(original_url)

    if parsed.scheme not in ("http", "https"):
        raise InvalidURLError(original_url, "URL must use http or https scheme")

    host = parsed.hostname
    if not host:
        raise InvalidURLError(original_url, "URL has no host")

    host = host.lower()

    # --- Platform detection ---
    if host in _YOUTUBE_HOSTS:
        raise UnsupportedPlatformError(original_url, host)

    platform = _HOST_TO_PLATFORM.get(host)
    if platform is None:
        raise UnsupportedPlatformError(original_url, host)

    # --- Path pattern validation ---
    if host not in _PATH_BYPASS_HOSTS:
        patterns = _PATH_PATTERNS.get(platform, [])
        path = parsed.path or "/"
        if not any(p.search(path) for p in patterns):
            raise InvalidContentPathError(original_url, platform, path)

    # --- Strip tracking parameters ---
    cleaned_url = _strip_tracking_params(parsed)

    return ValidatedURL(
        url=cleaned_url,
        platform=platform,
        original_url=original_url,
    )


def _strip_tracking_params(parsed: object) -> str:
    """Remove tracking query parameters while preserving platform-essential ones."""
    # parsed is a ParseResult but we type it loosely for readability
    query_params = parse_qs(parsed.query, keep_blank_values=False)  # type: ignore[attr-defined]

    cleaned_params = {
        k: v for k, v in query_params.items() if k.lower() not in _TRACKING_PARAMS
    }

    cleaned_query = urlencode(cleaned_params, doseq=True)

    return urlunparse(
        (
            parsed.scheme,  # type: ignore[attr-defined]
            parsed.netloc,  # type: ignore[attr-defined]
            parsed.path,  # type: ignore[attr-defined]
            parsed.params,  # type: ignore[attr-defined]
            cleaned_query,
            "",  # Drop fragment — not needed for extraction
        )
    )
