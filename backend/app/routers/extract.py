"""
Video extraction endpoint — POST /v1/extract

Receives a social media URL, validates it, extracts the video, and
returns metadata with a URL for the iOS client to retrieve the file.

Instagram: routed through RapidAPI (returns direct CDN URL).
Twitter/X, Twitch: routed through yt-dlp (returns signed proxy URL).
"""

import logging

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field
from slowapi import Limiter
from slowapi.util import get_remote_address

from app.auth import verify_api_key
from app.config import RAPIDAPI_KEY
from app.extraction import (
    ExtractionError,
    ExtractionTimeout,
    extract_video,
)
from app.extractors.instagram_rapidapi import extract_instagram_via_rapidapi
from app.signing import generate_signed_url
from app.validators.exceptions import (
    InvalidContentPathError,
    InvalidURLError,
    UnsupportedPlatformError,
)
from app.validators.url_validator import validate_url

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/v1", tags=["extraction"])

# Rate limiter — keyed by API key header, falling back to IP address
limiter = Limiter(key_func=get_remote_address)


# ---------------------------------------------------------------------------
# Request / Response models
# ---------------------------------------------------------------------------


class ExtractRequest(BaseModel):
    """Request body for POST /v1/extract."""

    url: str = Field(..., description="The social media URL to extract video from")


class ExtractResponse(BaseModel):
    """Successful response from POST /v1/extract."""

    status: str = "success"
    platform: str
    video_url: str
    duration: float
    width: int
    height: int
    file_size: int | None = None
    content_type: str = "video/mp4"
    title: str | None = None


class ErrorResponse(BaseModel):
    """Standard error response schema."""

    error: str
    detail: str


# ---------------------------------------------------------------------------
# Helper to build error responses
# ---------------------------------------------------------------------------


def _error(status_code: int, error_code: str, detail: str) -> HTTPException:
    """Create an HTTPException with the standard error JSON shape."""
    return HTTPException(
        status_code=status_code,
        detail={"error": error_code, "detail": detail},
    )


# ---------------------------------------------------------------------------
# Endpoint
# ---------------------------------------------------------------------------


@router.post(
    "/extract",
    response_model=ExtractResponse,
    responses={
        400: {"model": ErrorResponse, "description": "Invalid URL or unsupported platform"},
        401: {"model": ErrorResponse, "description": "Missing or invalid API key"},
        429: {"model": ErrorResponse, "description": "Rate limit exceeded"},
        502: {"model": ErrorResponse, "description": "Extraction failed"},
        504: {"model": ErrorResponse, "description": "Extraction timed out"},
    },
    summary="Extract video from a social media URL",
    description="Validates the URL, extracts the video via yt-dlp, and returns metadata with a signed download URL.",
)
@limiter.limit("10/minute;60/hour;200/day")
async def extract(
    body: ExtractRequest,
    request: Request,
    _api_key: str = Depends(verify_api_key),
) -> ExtractResponse:
    """Extract video from a social media URL."""

    # --- Step 1: Validate the URL ---
    try:
        validated = validate_url(body.url)
    except InvalidURLError as e:
        raise _error(400, "INVALID_URL", str(e))
    except UnsupportedPlatformError as e:
        raise _error(400, "UNSUPPORTED_PLATFORM", str(e))
    except InvalidContentPathError as e:
        raise _error(400, "INVALID_CONTENT_PATH", str(e))

    logger.info(
        "Extracting video: platform=%s url=%s",
        validated.platform, validated.url,
    )

    # --- Step 2: Extract video ---
    # Instagram → RapidAPI (direct CDN URL, 1-2s)
    # Twitter/X, Twitch → yt-dlp (backend proxies via signed URL)
    if validated.platform == "instagram" and RAPIDAPI_KEY:
        return await _extract_instagram(validated)
    else:
        return await _extract_via_ytdlp(validated)


async def _extract_instagram(validated) -> ExtractResponse:
    """Extract Instagram video via RapidAPI and return direct CDN URL."""
    try:
        result = await extract_instagram_via_rapidapi(validated.url)
    except ExtractionTimeout:
        raise _error(
            504,
            "EXTRACTION_TIMEOUT",
            "The extraction request timed out. Please try again.",
        )
    except ExtractionError as e:
        raise _error(502, "EXTRACTION_FAILED", e.detail)

    logger.info(
        "Instagram RapidAPI extraction complete: duration=%.1f",
        result["duration"],
    )

    return ExtractResponse(
        platform="instagram",
        video_url=result["video_url"],
        duration=result["duration"],
        width=result["width"],
        height=result["height"],
        file_size=result["file_size"],
        content_type=result["content_type"],
        title=result["title"],
    )


async def _extract_via_ytdlp(validated) -> ExtractResponse:
    """Extract video via yt-dlp (Twitter/X, Twitch) and return signed proxy URL."""
    try:
        result = await extract_video(
            url=validated.url,
            platform=validated.platform,
        )
    except ExtractionTimeout:
        raise _error(
            504,
            "EXTRACTION_TIMEOUT",
            "The extraction request timed out. Please try again.",
        )
    except ExtractionError as e:
        raise _error(502, "EXTRACTION_FAILED", e.detail)

    # Generate signed media URL for backend-proxied delivery
    media_url = generate_signed_url(result.file_id)

    logger.info(
        "yt-dlp extraction complete: platform=%s file_id=%s size=%d duration=%.1f",
        result.platform, result.file_id, result.file_size, result.duration,
    )

    return ExtractResponse(
        platform=result.platform,
        video_url=media_url,
        duration=result.duration,
        width=result.width,
        height=result.height,
        file_size=result.file_size,
    )
