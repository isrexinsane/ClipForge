"""
Video extraction service.

Twitter/X and Twitch use yt-dlp as an isolated subprocess (Architecture
Spec §7.3). Instagram uses RapidAPI (1-2s vs 30-90s with yt-dlp).
Reddit and YouTube are rejected at the URL validation layer.

yt-dlp proxy and cookie support (EXTRACT-CONFIG):
    - YTDLP_PROXY env var: passed as --proxy to yt-dlp. Use a residential
      proxy URL to avoid datacenter IP blocking by social media platforms.
    - YTDLP_COOKIES_CONTENT env var: Netscape-format cookie file contents,
      written to /tmp/clipforge_cookies.txt at startup and passed via --cookies.
"""

import asyncio
import json
import logging
import os
import shutil
import uuid
from dataclasses import dataclass
from pathlib import Path

logger = logging.getLogger(__name__)

# Directory for temporary video files. Created on import if it doesn't exist.
TEMP_DIR = Path("/tmp/clipforge")
TEMP_DIR.mkdir(parents=True, exist_ok=True)

# yt-dlp subprocess timeout in seconds (Twitter/X, Twitch).
EXTRACTION_TIMEOUT_SECONDS: int = 30

# Cookie file path for yt-dlp (general — not Instagram-specific).
COOKIES_FILE = Path("/tmp/clipforge_cookies.txt")

# Platform display names for error messages (yt-dlp platforms only)
_PLATFORM_DISPLAY_NAMES: dict[str, str] = {
    "twitter": "Twitter/X",
    "tiktok": "TikTok",
    "twitch": "Twitch",
}


def setup_cookies() -> None:
    """Write the general cookie file from environment variables at startup.

    Called during FastAPI lifespan startup. Writes the optional cookie file
    from YTDLP_COOKIES_CONTENT (Netscape format) for Twitter/X and Twitch.
    Instagram no longer uses yt-dlp — it goes through RapidAPI.
    """
    cookies_content: str | None = os.environ.get("YTDLP_COOKIES_CONTENT")
    if cookies_content:
        COOKIES_FILE.write_text(cookies_content)
        logger.info("Wrote general cookies file to %s", COOKIES_FILE)
    else:
        logger.info("YTDLP_COOKIES_CONTENT not set — no general cookies file")


def _build_proxy_args() -> list[str]:
    """Build --proxy arguments if YTDLP_PROXY is configured.

    Returns:
        ["--proxy", proxy_url] if configured, else [].
    """
    proxy_url: str | None = os.environ.get("YTDLP_PROXY")
    if proxy_url:
        return ["--proxy", proxy_url]
    return []


def _build_cookie_args() -> list[str]:
    """Build --cookies arguments if the general cookies file exists.

    Returns:
        ["--cookies", path] if the cookies file exists, else [].
    """
    if COOKIES_FILE.exists():
        return ["--cookies", str(COOKIES_FILE)]
    return []


def is_proxy_configured() -> bool:
    """Check whether a yt-dlp proxy is configured via environment variable."""
    return bool(os.environ.get("YTDLP_PROXY"))


def is_cookies_configured() -> bool:
    """Check whether the general cookie file exists for yt-dlp."""
    return COOKIES_FILE.exists()


@dataclass
class ExtractionResult:
    """Result of a successful video extraction."""

    file_id: str
    file_path: Path
    platform: str
    duration: float
    width: int
    height: int
    file_size: int


class ExtractionError(Exception):
    """yt-dlp failed to extract video."""

    def __init__(self, platform: str, detail: str) -> None:
        self.platform = platform
        self.detail = detail
        super().__init__(detail)


class ExtractionTimeout(Exception):
    """yt-dlp did not complete within the timeout window."""

    pass


async def extract_video(url: str, platform: str) -> ExtractionResult:
    """Extract video from a social media URL using yt-dlp.

    Used for Twitter/X and Twitch. Instagram is routed through RapidAPI
    at the router layer and never reaches this function.

    Args:
        url: The validated, cleaned URL to extract from.
        platform: The detected platform name (e.g., "twitter").

    Returns:
        An ExtractionResult with file path and video metadata.

    Raises:
        ExtractionError: yt-dlp failed (non-zero exit, no output file).
        ExtractionTimeout: yt-dlp exceeded the timeout.
    """
    file_id = str(uuid.uuid4())
    output_template = str(TEMP_DIR / f"{file_id}.%(ext)s")
    info_file = str(TEMP_DIR / f"{file_id}.info.json")

    # Resolve yt-dlp binary path — may not be on PATH in all environments
    ytdlp_bin = shutil.which("yt-dlp") or "yt-dlp"

    # yt-dlp command: cap at 720p MP4, write info JSON, no playlists
    cmd = [
        ytdlp_bin,
        "--no-playlist",
        "-f", "bestvideo[ext=mp4][height<=720]+bestaudio[ext=m4a]/best[ext=mp4][height<=720]/best[height<=720]",
        "--merge-output-format", "mp4",
        "-o", output_template,
        "--write-info-json",
        "--no-write-playlist-metafiles",
        *_build_proxy_args(),
        *_build_cookie_args(),
        url,
    ]

    display_name = _PLATFORM_DISPLAY_NAMES.get(platform, platform)
    timeout = EXTRACTION_TIMEOUT_SECONDS

    try:
        # Pass current env to subprocess so it inherits PATH
        env = os.environ.copy()
        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            env=env,
        )

        stdout, stderr = await asyncio.wait_for(
            process.communicate(),
            timeout=timeout,
        )

    except asyncio.TimeoutError:
        # Kill the hung process
        try:
            process.kill()
            await process.wait()
        except ProcessLookupError:
            pass
        logger.error("yt-dlp timed out after %ds for %s", timeout, url)
        raise ExtractionTimeout()

    if process.returncode != 0:
        stderr_text = stderr.decode(errors="replace").strip()
        logger.error(
            "yt-dlp failed (exit %d) for %s: %s",
            process.returncode, url, stderr_text,
        )
        raise ExtractionError(
            platform=display_name,
            detail=(
                f"Could not retrieve video from {display_name}. "
                "The post may be deleted or private."
            ),
        )

    # Find the output file (yt-dlp determines the actual extension)
    output_file = _find_output_file(file_id)
    if output_file is None:
        raise ExtractionError(
            platform=display_name,
            detail=f"Could not retrieve video from {display_name}. No output file was created.",
        )

    # Extract metadata from info JSON or fall back to file stats
    metadata = _read_metadata(info_file, output_file)

    return ExtractionResult(
        file_id=file_id,
        file_path=output_file,
        platform=platform,
        duration=metadata["duration"],
        width=metadata["width"],
        height=metadata["height"],
        file_size=output_file.stat().st_size,
    )


def _find_output_file(file_id: str) -> Path | None:
    """Find the downloaded video file by its UUID prefix."""
    for f in TEMP_DIR.iterdir():
        if f.name.startswith(file_id) and not f.name.endswith(".info.json"):
            return f
    return None


def _read_metadata(info_file: str, video_file: Path) -> dict:
    """Read video metadata from yt-dlp's info JSON.

    Falls back to reasonable defaults if the info file is missing or
    incomplete — the extraction still succeeds, just with less metadata.
    """
    defaults = {
        "duration": 0.0,
        "width": 0,
        "height": 0,
    }

    try:
        with open(info_file) as f:
            info = json.load(f)

        return {
            "duration": float(info.get("duration") or 0),
            "width": int(info.get("width") or 0),
            "height": int(info.get("height") or 0),
        }
    except (FileNotFoundError, json.JSONDecodeError, ValueError) as e:
        logger.warning("Could not read info JSON %s: %s", info_file, e)
        return defaults
