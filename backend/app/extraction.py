"""
Video extraction service using yt-dlp as an isolated subprocess.

yt-dlp is invoked via asyncio subprocess (not imported as a library) to
provide process isolation and timeout control per Architecture Spec §7.3.
If yt-dlp hangs or crashes, only the subprocess is affected.

Proxy and cookie support (EXTRACT-CONFIG):
    - YTDLP_PROXY env var: passed as --proxy to yt-dlp. Use a residential
      proxy URL to avoid datacenter IP blocking by social media platforms.
    - YTDLP_COOKIES_CONTENT env var: Netscape-format cookie file contents,
      written to /tmp/clipforge_cookies.txt at startup and passed via --cookies.
    - INSTAGRAM_SESSION_COOKIE env var: Instagram sessionid cookie value,
      written to a platform-specific cookie file for Instagram extractions.
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

# yt-dlp subprocess timeout in seconds.
# Reddit requires longer because yt-dlp downloads separate audio + video
# streams and merges them via ffmpeg, which exceeds 30s through a proxy.
EXTRACTION_TIMEOUT_SECONDS: int = 30
REDDIT_EXTRACTION_TIMEOUT_SECONDS: int = 60

# Cookie file paths
COOKIES_FILE = Path("/tmp/clipforge_cookies.txt")
INSTAGRAM_COOKIES_FILE = Path("/tmp/clipforge_instagram_cookies.txt")

# Platform display names for error messages
_PLATFORM_DISPLAY_NAMES: dict[str, str] = {
    "twitter": "Twitter/X",
    "instagram": "Instagram",
    "reddit": "Reddit",
    "tiktok": "TikTok",
    "twitch": "Twitch",
}


def setup_cookies() -> None:
    """Write cookie files from environment variables at startup.

    Called during FastAPI lifespan startup. Writes two optional cookie files:
    1. General cookies from YTDLP_COOKIES_CONTENT (Netscape format, any platform).
    2. Instagram-specific cookies from INSTAGRAM_SESSION_COOKIE (sessionid only).

    If the env vars are not set, the corresponding files are not created
    and yt-dlp runs without --cookies for those cases.
    """
    # General cookies file
    cookies_content: str | None = os.environ.get("YTDLP_COOKIES_CONTENT")
    if cookies_content:
        COOKIES_FILE.write_text(cookies_content)
        logger.info("Wrote general cookies file to %s", COOKIES_FILE)
    else:
        logger.info("YTDLP_COOKIES_CONTENT not set — no general cookies file")

    # Instagram-specific session cookie
    ig_session: str | None = os.environ.get("INSTAGRAM_SESSION_COOKIE")
    if ig_session:
        # Netscape cookie format: domain, flag, path, secure, expiry, name, value
        netscape_header = "# Netscape HTTP Cookie File\n"
        cookie_line = f".instagram.com\tTRUE\t/\tTRUE\t0\tsessionid\t{ig_session}\n"
        INSTAGRAM_COOKIES_FILE.write_text(netscape_header + cookie_line)
        logger.info("Wrote Instagram cookies file to %s", INSTAGRAM_COOKIES_FILE)
    else:
        logger.info("INSTAGRAM_SESSION_COOKIE not set — no Instagram cookies file")


def _build_proxy_args() -> list[str]:
    """Build --proxy arguments if YTDLP_PROXY is configured.

    Returns:
        ["--proxy", proxy_url] if configured, else [].
    """
    proxy_url: str | None = os.environ.get("YTDLP_PROXY")
    if proxy_url:
        return ["--proxy", proxy_url]
    return []


def _build_cookie_args(platform: str) -> list[str]:
    """Build --cookies arguments based on platform and available cookie files.

    Instagram extractions prefer the Instagram-specific cookie file if it
    exists. All other platforms use the general cookies file. If neither
    exists, no --cookies argument is added.

    Args:
        platform: The detected platform name (e.g., "instagram").

    Returns:
        ["--cookies", path] if a cookies file exists, else [].
    """
    # Instagram-specific cookies take priority for Instagram URLs
    if platform == "instagram" and INSTAGRAM_COOKIES_FILE.exists():
        return ["--cookies", str(INSTAGRAM_COOKIES_FILE)]

    # General cookies file for all platforms
    if COOKIES_FILE.exists():
        return ["--cookies", str(COOKIES_FILE)]

    return []


def _build_instagram_codec_args(platform: str) -> list[str]:
    """Build codec preference args for Instagram extractions.

    Instagram often returns HEVC (H.265) video, which causes playback
    issues in iOS Simulator and may cause GIF encoding failures.
    These args tell yt-dlp to prefer H.264 streams and, as a fallback,
    transcode to H.264 MP4 server-side if no native H.264 stream exists.

    Only applied to Instagram — other platforms return H.264 natively.

    Args:
        platform: The detected platform name.

    Returns:
        ["-S", "vcodec:h264", "--recode-video", "mp4"] for Instagram, else [].
    """
    if platform == "instagram":
        return ["-S", "vcodec:h264", "--recode-video", "mp4"]
    return []


def is_proxy_configured() -> bool:
    """Check whether a yt-dlp proxy is configured via environment variable."""
    return bool(os.environ.get("YTDLP_PROXY"))


def is_cookies_configured() -> bool:
    """Check whether any cookie file exists for yt-dlp."""
    return COOKIES_FILE.exists() or INSTAGRAM_COOKIES_FILE.exists()


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

    Args:
        url: The validated, cleaned URL to extract from.
        platform: The detected platform name (e.g., "twitter").

    Returns:
        An ExtractionResult with file path and video metadata.

    Raises:
        ExtractionError: yt-dlp failed (non-zero exit, no output file).
        ExtractionTimeout: yt-dlp exceeded the platform timeout (60s Reddit, 30s others).
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
        *_build_cookie_args(platform),
        *_build_instagram_codec_args(platform),
        url,
    ]

    display_name = _PLATFORM_DISPLAY_NAMES.get(platform, platform)
    timeout = REDDIT_EXTRACTION_TIMEOUT_SECONDS if platform == "reddit" else EXTRACTION_TIMEOUT_SECONDS

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
