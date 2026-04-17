"""
Application configuration loaded from environment variables.

All secrets and deployment-specific values are read from the environment,
never hardcoded. See .env.example for the full list.
"""

import logging
import os

logger = logging.getLogger(__name__)

# API authentication key — required in production, optional during development.
# If unset, the server starts but logs a warning.
CLIPFORGE_API_KEY: str | None = os.environ.get("CLIPFORGE_API_KEY")

if CLIPFORGE_API_KEY is None:
    logger.warning(
        "CLIPFORGE_API_KEY is not set. The server will start, but API "
        "authentication will not be enforced. Set this variable before deploying."
    )

# Server configuration
HOST: str = os.environ.get("HOST", "0.0.0.0")
PORT: int = int(os.environ.get("PORT", "8000"))

# RapidAPI key for Instagram Video Downloader (replaces yt-dlp for Instagram).
# Read from environment — never hardcoded.
RAPIDAPI_KEY: str = os.environ.get("RAPIDAPI_KEY", "")

if not RAPIDAPI_KEY:
    logger.warning(
        "RAPIDAPI_KEY is not set. Instagram extraction will fall back to yt-dlp."
    )

# Supported platforms — the canonical list shared with the iOS client
# via the /v1/health response. YouTube is intentionally excluded from MVP.
SUPPORTED_PLATFORMS: list[str] = [
    "twitter",
    "instagram",
    "tiktok",
    "twitch",
]
