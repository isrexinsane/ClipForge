"""
Media file serving endpoint — GET /v1/media/{file_id}

Streams extracted video files to the iOS client. Authenticated via
signed URL tokens (not the X-API-Key header), so the client can
use a plain URLSession download task with no custom headers.
"""

import logging
import re
from pathlib import Path

from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import FileResponse

from app.extraction import TEMP_DIR
from app.signing import verify_signed_url

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/v1", tags=["media"])

# Only allow UUID characters in file IDs (letters, digits, hyphens)
_SAFE_FILE_ID = re.compile(r"^[a-zA-Z0-9\-]+$")


@router.get(
    "/media/{file_id}",
    summary="Retrieve extracted video file",
    description="Streams the video file identified by file_id. Requires a valid signed URL token.",
    responses={
        400: {"description": "Invalid file ID (path traversal attempt)"},
        403: {"description": "Invalid or expired token"},
        410: {"description": "File has expired or does not exist"},
    },
)
async def get_media(
    file_id: str,
    token: str = Query(..., description="HMAC-SHA256 signature"),
    expires: int = Query(..., description="Unix timestamp when the URL expires"),
) -> FileResponse:
    """Serve an extracted video file by its ID."""

    # --- Path traversal guard ---
    if not _SAFE_FILE_ID.match(file_id):
        raise HTTPException(
            status_code=400,
            detail={"error": "INVALID_REQUEST", "detail": "Invalid file ID."},
        )

    # --- Signed URL verification ---
    if not verify_signed_url(file_id, token, expires):
        raise HTTPException(
            status_code=403,
            detail={
                "error": "INVALID_TOKEN",
                "detail": "The media URL token is invalid or has expired.",
            },
        )

    # --- Locate the file ---
    file_path = _find_file(file_id)
    if file_path is None:
        raise HTTPException(
            status_code=410,
            detail={
                "error": "MEDIA_EXPIRED",
                "detail": "This video has expired. Please import the link again.",
            },
        )

    logger.info("Serving media file: %s (%d bytes)", file_id, file_path.stat().st_size)

    return FileResponse(
        path=str(file_path),
        media_type="video/mp4",
        filename=f"{file_id}.mp4",
    )


def _find_file(file_id: str) -> Path | None:
    """Find a video file by its UUID prefix in the temp directory.

    Returns the Path if found, None otherwise. Only matches files
    that start with the file_id (yt-dlp may add extensions).
    """
    for f in TEMP_DIR.iterdir():
        if f.name.startswith(file_id) and not f.name.endswith(".info.json"):
            return f
    return None
