"""
API key authentication dependency.

Used by endpoints that require app-level authentication (currently just
the extraction endpoint). The media endpoint authenticates via signed
URL tokens instead — see app/routers/media.py (STORY-007).
"""

from fastapi import Header, HTTPException

from app.config import CLIPFORGE_API_KEY


async def verify_api_key(x_api_key: str = Header(alias="X-API-Key")) -> str:
    """FastAPI dependency that validates the X-API-Key header.

    Returns the validated key on success. Raises HTTP 401 on failure.
    If CLIPFORGE_API_KEY is not configured, all requests are allowed
    (development mode).
    """
    if CLIPFORGE_API_KEY is None:
        # Development mode — no key configured, allow everything
        return x_api_key

    if x_api_key != CLIPFORGE_API_KEY:
        raise HTTPException(
            status_code=401,
            detail={
                "error": "UNAUTHORIZED",
                "detail": "Missing or invalid API key.",
            },
        )

    return x_api_key
