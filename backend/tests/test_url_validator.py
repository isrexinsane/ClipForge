"""
Unit tests for URL validation and platform detection.

Covers all acceptance criteria from STORY-005:
- 5 valid URLs (one per platform)
- 1 YouTube URL → UnsupportedPlatformError
- 1 malformed URL → InvalidURLError
- 5 non-video paths (one per platform) → InvalidContentPathError
- 1 tracking parameter stripping test
- Additional edge cases
"""

import pytest

from app.validators.exceptions import (
    InvalidContentPathError,
    InvalidURLError,
    UnsupportedPlatformError,
)
from app.validators.url_validator import validate_url


# -----------------------------------------------------------------------
# Valid URLs — one per platform (AC-2)
# -----------------------------------------------------------------------


class TestValidURLs:
    """Each supported platform should validate successfully with a correct video URL."""

    def test_twitter_status_url(self) -> None:
        result = validate_url("https://x.com/user/status/1234567890")
        assert result.platform == "twitter"
        assert "x.com" in result.url

    def test_instagram_reel_url(self) -> None:
        result = validate_url("https://www.instagram.com/reel/ABC123xyz/")
        assert result.platform == "instagram"
        assert "/reel/" in result.url

    def test_reddit_comments_url(self) -> None:
        result = validate_url(
            "https://www.reddit.com/r/funny/comments/abc123/some_title/"
        )
        assert result.platform == "reddit"
        assert "/comments/" in result.url

    def test_tiktok_video_url(self) -> None:
        result = validate_url(
            "https://www.tiktok.com/@username/video/7123456789012345678"
        )
        assert result.platform == "tiktok"
        assert "/video/" in result.url

    def test_twitch_clip_url(self) -> None:
        result = validate_url(
            "https://www.twitch.tv/channel_name/clip/AmazingClipSlug"
        )
        assert result.platform == "twitch"
        assert "/clip/" in result.url


# -----------------------------------------------------------------------
# YouTube rejection (AC-3)
# -----------------------------------------------------------------------


class TestYouTubeRejection:
    """YouTube URLs must be explicitly rejected with UnsupportedPlatformError."""

    def test_youtube_url_rejected(self) -> None:
        with pytest.raises(UnsupportedPlatformError) as exc_info:
            validate_url("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
        assert "youtube.com" in str(exc_info.value)

    def test_youtu_be_short_link_rejected(self) -> None:
        with pytest.raises(UnsupportedPlatformError):
            validate_url("https://youtu.be/dQw4w9WgXcQ")


# -----------------------------------------------------------------------
# Malformed URLs (AC-4)
# -----------------------------------------------------------------------


class TestMalformedURLs:
    """Structurally invalid URLs must raise InvalidURLError."""

    def test_missing_scheme(self) -> None:
        with pytest.raises(InvalidURLError):
            validate_url("twitter.com/user/status/123")

    def test_ftp_scheme_rejected(self) -> None:
        with pytest.raises(InvalidURLError):
            validate_url("ftp://twitter.com/user/status/123")

    def test_empty_string(self) -> None:
        with pytest.raises(InvalidURLError):
            validate_url("")


# -----------------------------------------------------------------------
# Tracking parameter stripping (AC-5)
# -----------------------------------------------------------------------


class TestTrackingParamStripping:
    """Tracking query parameters must be removed; essential params preserved."""

    def test_utm_params_stripped(self) -> None:
        url = "https://x.com/user/status/123?utm_source=twitter&utm_medium=social&s=20"
        result = validate_url(url)
        assert "utm_source" not in result.url
        assert "utm_medium" not in result.url
        assert "s=" not in result.url

    def test_essential_params_preserved(self) -> None:
        url = "https://www.reddit.com/r/sub/comments/abc/title/?context=3&utm_source=share"
        result = validate_url(url)
        assert "context=3" in result.url
        assert "utm_source" not in result.url


# -----------------------------------------------------------------------
# Non-video path rejection (AC-6)
# -----------------------------------------------------------------------


class TestInvalidContentPaths:
    """URLs on supported platforms but with non-video paths must be rejected."""

    def test_twitter_profile_page(self) -> None:
        with pytest.raises(InvalidContentPathError) as exc_info:
            validate_url("https://x.com/username")
        assert exc_info.value.platform == "twitter"

    def test_instagram_profile_page(self) -> None:
        with pytest.raises(InvalidContentPathError) as exc_info:
            validate_url("https://www.instagram.com/username/")
        assert exc_info.value.platform == "instagram"

    def test_reddit_subreddit_page(self) -> None:
        with pytest.raises(InvalidContentPathError) as exc_info:
            validate_url("https://www.reddit.com/r/funny/")
        assert exc_info.value.platform == "reddit"

    def test_tiktok_profile_page(self) -> None:
        with pytest.raises(InvalidContentPathError) as exc_info:
            validate_url("https://www.tiktok.com/@username")
        assert exc_info.value.platform == "tiktok"

    def test_twitch_channel_page(self) -> None:
        with pytest.raises(InvalidContentPathError) as exc_info:
            validate_url("https://www.twitch.tv/channel_name")
        assert exc_info.value.platform == "twitch"


# -----------------------------------------------------------------------
# Path bypass hosts (short links / direct video)
# -----------------------------------------------------------------------


class TestPathBypassHosts:
    """Hosts like v.redd.it and vm.tiktok.com skip path validation."""

    def test_vredd_it_direct_link(self) -> None:
        result = validate_url("https://v.redd.it/abc123def")
        assert result.platform == "reddit"

    def test_vm_tiktok_short_link(self) -> None:
        result = validate_url("https://vm.tiktok.com/ZMxxxxxxx/")
        assert result.platform == "tiktok"

    def test_clips_twitch_tv(self) -> None:
        result = validate_url("https://clips.twitch.tv/AmazingClipSlug")
        assert result.platform == "twitch"


# -----------------------------------------------------------------------
# Unsupported platform (not YouTube)
# -----------------------------------------------------------------------


class TestUnsupportedPlatform:
    """Random domains must raise UnsupportedPlatformError."""

    def test_random_domain(self) -> None:
        with pytest.raises(UnsupportedPlatformError):
            validate_url("https://example.com/some/video")
