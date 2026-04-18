"""
Instagram video extraction via RapidAPI (Instagram Video Downloader).

Replaces yt-dlp for Instagram — RapidAPI responds in 1-2 seconds vs
30-90 seconds for yt-dlp with server-side H.264 transcoding.

The API returns a direct CDN URL to the video file, so the backend
does NOT need to download and proxy the video. The iOS app downloads
directly from the CDN.
"""

import logging
from urllib.parse import urlparse, urlunparse

import httpx

from app.config import RAPIDAPI_KEY
from app.extraction import ExtractionError, ExtractionTimeout

logger = logging.getLogger(__name__)

# RapidAPI endpoint and host header
_RAPIDAPI_URL = "https://instagram-video-downloader13.p.rapidapi.com/index.php"
_RAPIDAPI_HOST = "instagram-video-downloader13.p.rapidapi.com"

# 15 seconds is generous — the API typically responds in 1-2s.
_TIMEOUT_SECONDS = 15


def _clean_instagram_url(url: str) -> str:
    """Strip tracking params (?igsh=, ?utm_source=, etc.) from an Instagram URL.

    Instagram URLs don't need query parameters for extraction. Tracking
    params can confuse the RapidAPI extractor.
    """
    parsed = urlparse(url)
    clean = urlunparse((parsed.scheme, parsed.netloc, parsed.path, "", "", ""))
    if not clean.endswith("/"):
        clean += "/"
    return clean


def _parse_resolution(resolution: str) -> tuple[int, int]:
    """Parse a resolution string like '640x1136' into (width, height).

    Returns (0, 0) if the string can't be parsed.
    """
    try:
        parts = resolution.lower().rstrip("p").split("x")
        if len(parts) == 2:
            return int(parts[0]), int(parts[1])
    except (ValueError, IndexError):
        pass
    return 0, 0


async def extract_instagram_via_rapidapi(url: str) -> dict:
    """Extract video from an Instagram URL via RapidAPI.

    Args:
        url: The validated Instagram URL (reel or post).

    Returns:
        A dict matching the shape expected by the extract router:
        {
            "video_url": str,   # Direct CDN URL (absolute)
            "duration": float,
            "width": int,
            "height": int,
            "file_size": int | None,
            "content_type": str,
            "title": str | None,
        }

    Raises:
        ExtractionError: The API returned an error or no video media.
        ExtractionTimeout: The API did not respond within the timeout.
    """
    clean_url = _clean_instagram_url(url)
    logger.info("Instagram URL cleaned: %s → %s", url, clean_url)

    headers = {
        "x-rapidapi-key": RAPIDAPI_KEY,
        "x-rapidapi-host": _RAPIDAPI_HOST,
        "Content-Type": "application/x-www-form-urlencoded",
    }

    try:
        async with httpx.AsyncClient(timeout=_TIMEOUT_SECONDS) as client:
            response = await client.post(
                _RAPIDAPI_URL,
                headers=headers,
                data={"url": clean_url},
            )
    except httpx.TimeoutException:
        logger.error("RapidAPI timeout after %ds for %s", _TIMEOUT_SECONDS, url)
        raise ExtractionTimeout()
    except httpx.HTTPError as e:
        logger.error("RapidAPI HTTP error for %s: %s", url, e)
        raise ExtractionError(
            platform="Instagram",
            detail="Could not retrieve video from Instagram. The post may be deleted or private.",
        )

    if response.status_code != 200:
        logger.error(
            "RapidAPI returned status %d for %s: %s",
            response.status_code, url, response.text[:500],
        )
        raise ExtractionError(
            platform="Instagram",
            detail="Could not retrieve video from Instagram. The post may be deleted or private.",
        )

    data = response.json()
    logger.info("RapidAPI response success=%s for %s", data.get("success"), url)

    if not data.get("success"):
        raise ExtractionError(
            platform="Instagram",
            detail="Could not retrieve video from Instagram. The post may be deleted or private.",
        )

    # Find the first video media item
    medias = data.get("medias") or []
    video_media = next((m for m in medias if m.get("type") == "video"), None)

    if video_media is None:
        raise ExtractionError(
            platform="Instagram",
            detail="Could not retrieve video from Instagram. The post may not contain video content.",
        )

    video_url = video_media.get("url")
    if not video_url:
        raise ExtractionError(
            platform="Instagram",
            detail="Could not retrieve video from Instagram. No video URL in response.",
        )

    # Parse resolution (e.g., "640x1136")
    width, height = _parse_resolution(video_media.get("resolution", ""))

    duration = float(data.get("duration") or 0)
    title = data.get("title") or None

    logger.info(
        "Instagram RapidAPI extraction complete: duration=%.1f resolution=%dx%d url=%s",
        duration, width, height, video_url[:80],
    )

    return {
        "video_url": video_url,
        "duration": duration,
        "width": width,
        "height": height,
        "file_size": None,
        "content_type": "video/mp4",
        "title": title,
    }
