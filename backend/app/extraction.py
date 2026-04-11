"""
Video extraction service using yt-dlp as an isolated subprocess.

yt-dlp is invoked via asyncio subprocess (not imported as a library) to
provide process isolation and timeout control per Architecture Spec §7.3.
If yt-dlp hangs or crashes, only the subprocess is affected.
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

# yt-dlp subprocess timeout in seconds
EXTRACTION_TIMEOUT_SECONDS: int = 30

# Platform display names for error messages
_PLATFORM_DISPLAY_NAMES: dict[str, str] = {
    "twitter": "Twitter/X",
    "instagram": "Instagram",
    "reddit": "Reddit",
    "tiktok": "TikTok",
    "twitch": "Twitch",
}


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
        ExtractionTimeout: yt-dlp exceeded the 30-second timeout.
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
        "-f", "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[height<=720][ext=mp4]/best[height<=720]",
        "--merge-output-format", "mp4",
        "-o", output_template,
        "--write-info-json",
        "--no-write-playlist-metafiles",
        url,
    ]

    display_name = _PLATFORM_DISPLAY_NAMES.get(platform, platform)

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
            timeout=EXTRACTION_TIMEOUT_SECONDS,
        )

    except asyncio.TimeoutError:
        # Kill the hung process
        try:
            process.kill()
            await process.wait()
        except ProcessLookupError:
            pass
        logger.error("yt-dlp timed out after %ds for %s", EXTRACTION_TIMEOUT_SECONDS, url)
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
