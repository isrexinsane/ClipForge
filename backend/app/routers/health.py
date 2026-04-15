"""
Health check endpoint — GET /v1/health

Returns the server status, installed yt-dlp version, the list of
supported platforms, and proxy/cookie configuration status. No
authentication required. Used as a deployment smoke test: if this
returns 200, the server is running and yt-dlp is installed.

The proxy_configured and cookies_configured fields let operators verify
that EXTRACT-CONFIG settings are active without exposing credentials.
"""

import time

from fastapi import APIRouter
from pydantic import BaseModel

from app.config import SUPPORTED_PLATFORMS
from app.extraction import is_cookies_configured, is_proxy_configured

router = APIRouter(prefix="/v1", tags=["health"])

# Track server start time for uptime calculation
_start_time = time.time()


class HealthResponse(BaseModel):
    """Response schema for the health endpoint."""

    status: str
    yt_dlp_version: str
    supported_platforms: list[str]
    uptime_seconds: int
    proxy_configured: bool
    cookies_configured: bool


@router.get(
    "/health",
    response_model=HealthResponse,
    summary="Health check",
    description="Returns server status, yt-dlp version, supported platforms, and extraction config status.",
)
async def health_check() -> HealthResponse:
    """Lightweight health check. No authentication required."""
    import yt_dlp.version

    return HealthResponse(
        status="ok",
        yt_dlp_version=yt_dlp.version.__version__,
        supported_platforms=SUPPORTED_PLATFORMS,
        uptime_seconds=int(time.time() - _start_time),
        proxy_configured=is_proxy_configured(),
        cookies_configured=is_cookies_configured(),
    )
