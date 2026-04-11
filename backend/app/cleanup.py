"""
Background cleanup task for expired media files.

Runs every 5 minutes and removes files in /tmp/clipforge/ older than
10 minutes. This prevents the VPS disk from filling up with orphaned
video files from abandoned or failed requests.
"""

import asyncio
import logging
import os
import time
from pathlib import Path

from app.extraction import TEMP_DIR

logger = logging.getLogger(__name__)

# Files older than this (in seconds) are deleted
MAX_FILE_AGE_SECONDS: int = 600  # 10 minutes

# How often the cleanup loop runs
CLEANUP_INTERVAL_SECONDS: int = 300  # 5 minutes


async def cleanup_loop() -> None:
    """Background task that periodically removes expired media files."""
    logger.info(
        "Cleanup task started: checking every %ds, removing files older than %ds",
        CLEANUP_INTERVAL_SECONDS,
        MAX_FILE_AGE_SECONDS,
    )
    while True:
        try:
            await asyncio.sleep(CLEANUP_INTERVAL_SECONDS)
            cleanup_expired_files()
        except asyncio.CancelledError:
            logger.info("Cleanup task cancelled — shutting down")
            break
        except Exception:
            logger.exception("Error in cleanup loop")


def cleanup_expired_files() -> int:
    """Remove files older than MAX_FILE_AGE_SECONDS from the temp directory.

    Returns the number of files deleted. Safe to call from tests.
    """
    if not TEMP_DIR.exists():
        return 0

    now = time.time()
    deleted = 0

    for f in TEMP_DIR.iterdir():
        if not f.is_file():
            continue
        try:
            age = now - os.path.getmtime(f)
            if age > MAX_FILE_AGE_SECONDS:
                f.unlink()
                deleted += 1
                logger.debug("Deleted expired file: %s (age: %.0fs)", f.name, age)
        except OSError as e:
            logger.warning("Could not delete %s: %s", f.name, e)

    if deleted > 0:
        logger.info("Cleanup removed %d expired file(s)", deleted)

    return deleted
