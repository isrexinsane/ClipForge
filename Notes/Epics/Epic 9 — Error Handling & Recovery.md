# Epic 9 — Error Handling & Recovery

**Status:** ⬜ Not Started

## Scope

Implement robust error handling and user-friendly recovery flows across all features.

- **Invalid URLs:** Clear error message, suggestion to copy link again
- **Network failures:** Retry button, offline indicator
- **Extraction timeouts:** Retry with longer timeout or fallback message
- **Unsupported platforms:** List of supported platforms in error message
- **Encoding failures:** Fallback to smaller frame rate/dimensions, or fail gracefully
- **Permissions:** Handle Photos library permission denial, prompt user to enable in Settings
- **Rate limiting:** Display retry_after countdown, hint user to try again later

## Implementation

- `ErrorMapper` converts API error codes to user-friendly messages
- `RetryManager` handles exponential backoff for network calls
- Alert and toast UI patterns for different error severity levels

## Dependencies

- All previous epics (3–8) — each feature produces potential error cases

## Wikilinks

- [[API_Contract]] — Error code reference
- [[Architecture_Spec]] — Error handling architecture
- [[Epic_Breakdown]] — Full plan
- [[Dashboard]] — Sprint tracking

## Notes

Error handling is low priority during initial development but critical for TestFlight beta feedback.
