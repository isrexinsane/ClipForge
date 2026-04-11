"""
Signed URL generation and verification for media file access.

The extraction endpoint generates a signed URL; the media endpoint
verifies it. The signature is an HMAC-SHA256 over "{file_id}:{expires}"
using the CLIPFORGE_API_KEY as the signing secret.

This allows the iOS client to fetch video files with a plain URLSession
download — no X-API-Key header needed on the media request.
"""

import hashlib
import hmac
import time

from app.config import CLIPFORGE_API_KEY

# Signed URLs are valid for 10 minutes
MEDIA_URL_TTL_SECONDS: int = 600

# Fallback signing key for development when CLIPFORGE_API_KEY is not set
_SIGNING_KEY: str = CLIPFORGE_API_KEY or "dev-signing-key-not-for-production"


def generate_signed_url(file_id: str, base_path: str = "/v1/media") -> str:
    """Generate a signed media URL for the given file ID.

    Args:
        file_id: The unique identifier for the extracted video file.
        base_path: The base URL path for the media endpoint.

    Returns:
        A relative URL string like /v1/media/{file_id}?token=abc&expires=123
    """
    expires = int(time.time()) + MEDIA_URL_TTL_SECONDS
    token = _compute_token(file_id, expires)
    return f"{base_path}/{file_id}?token={token}&expires={expires}"


def verify_signed_url(file_id: str, token: str, expires: int) -> bool:
    """Verify a signed media URL token.

    Args:
        file_id: The file ID from the URL path.
        token: The HMAC token from the query parameter.
        expires: The Unix timestamp from the query parameter.

    Returns:
        True if the token is valid and not expired.
    """
    if int(time.time()) > expires:
        return False

    expected_token = _compute_token(file_id, expires)
    return hmac.compare_digest(token, expected_token)


def _compute_token(file_id: str, expires: int) -> str:
    """Compute HMAC-SHA256 signature for a file ID and expiry timestamp."""
    message = f"{file_id}:{expires}"
    return hmac.new(
        _SIGNING_KEY.encode(),
        message.encode(),
        hashlib.sha256,
    ).hexdigest()
