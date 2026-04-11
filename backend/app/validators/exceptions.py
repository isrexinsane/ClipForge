"""
Custom exceptions for URL validation.

Each exception carries enough context for the API endpoint to construct
the correct error response (error code, HTTP status, detail message).
"""


class InvalidURLError(Exception):
    """Raised when the input is not a valid URL (missing scheme, empty host, etc.)."""

    def __init__(self, url: str, reason: str = "Malformed URL") -> None:
        self.url = url
        self.reason = reason
        super().__init__(f"Invalid URL '{url}': {reason}")


class UnsupportedPlatformError(Exception):
    """Raised when the URL's host is not in the supported platforms allowlist."""

    def __init__(self, url: str, host: str) -> None:
        self.url = url
        self.host = host
        super().__init__(
            f"The URL host '{host}' is not in the supported platforms list."
        )


class InvalidContentPathError(Exception):
    """Raised when the URL belongs to a supported platform but the path
    does not match a recognized video content pattern."""

    def __init__(self, url: str, platform: str, path: str) -> None:
        self.url = url
        self.platform = platform
        self.path = path
        super().__init__(
            f"The path '{path}' does not match a video content pattern for {platform}."
        )
