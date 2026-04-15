# Blockers

Active blockers preventing progress on planned work. Updated as new blockers are discovered or resolved.

---

## EXTRACT-CONFIG (HIGH PRIORITY)

**Status:** OPEN  
**Discovered:** 2026-04-11 (Sprint 1 QA)  
**Blocks:** [[Epic 3 — Video Import Flow]] end-to-end testing and feature development

### Problem

All five platform extractions (Twitter, Instagram, Reddit, TikTok, Twitch) return **502 EXTRACTION_FAILED** during Railway smoke testing.

This is NOT a code bug. The full backend pipeline executes correctly:
1. URL validation ✅
2. Platform detection ✅
3. yt-dlp subprocess invocation ✅
4. Error handling ✅

The issue: yt-dlp requests originating from Railway's datacenter IPs are being blocked or rate-limited by social media platforms.

### Root Cause

Social media platforms (Twitter, Instagram, etc.) actively block or deprioritize requests from cloud datacenter IP ranges (AWS, Azure, Railway, etc.) to prevent scraping and bot activity. yt-dlp must appear as a real browser user to bypass these blocks.

### Solution

Configure yt-dlp with one or both of the following:

1. **Browser cookies (--cookies flag)**
   - Extract browser cookies from a real user session (Firefox, Chrome)
   - Pass to yt-dlp via --cookies-from-browser or --cookies file
   - Makes requests appear authenticated and human-like
   - Downside: cookies expire; requires periodic refresh

2. **Residential proxy (--proxy flag)**
   - Purchase residential proxy service (Bright Data, Oxylabs, etc.)
   - Route yt-dlp requests through residential IPs (real home internet addresses)
   - More reliable; prevents platform blocking
   - Cost: ~$50–200/month for sufficient quota

### Next Steps

1. Evaluate cookie auth vs. proxy cost/reliability trade-off
2. Implement chosen solution in `/extract` endpoint (ExtractService.py)
3. Test with sample URLs from each platform
4. Validate 200 responses and correct video metadata
5. Update smoke test suite to include real-world URLs
6. Unblock Epic 3

### Related Documentation

- [[Epic 2 — Backend API]] § Carry-Forward Blockers
- [[Sprint 1 Retrospective]] § What to Watch

---

## AUTH-FIX (LOW PRIORITY)

**Status:** OPEN  
**Discovered:** 2026-04-11 (Sprint 1 QA)  
**Blocks:** None (minor cleanup)

### Problem

FastAPI returns **422 Unprocessable Entity** (validation error) when the `X-API-Key` header is missing entirely.

**API Contract specifies:** 401 UNAUTHORIZED with error JSON:
```json
{
  "status": "error",
  "error_code": "UNAUTHORIZED",
  "message": "Missing or invalid API key"
}
```

### Root Cause

FastAPI's default request validation intercepts missing headers before custom code can run. The header dependency raises a validation error (422) instead of letting custom middleware handle it as an auth error (401).

### Solution

Add a custom FastAPI dependency or middleware that:
1. Checks for `X-API-Key` header before Pydantic validation
2. Returns 401 UNAUTHORIZED if missing or invalid
3. Allows request to proceed if valid

Simple middleware approach:
```python
@app.middleware("http")
async def auth_middleware(request: Request, call_next):
    if request.url.path == "/v1/health":
        return await call_next(request)
    
    api_key = request.headers.get("X-API-Key")
    if not api_key or not is_valid_key(api_key):
        return JSONResponse(
            status_code=401,
            content={"status": "error", "error_code": "UNAUTHORIZED", "message": "..."}
        )
    return await call_next(request)
```

### Impact

Non-blocking. iOS client always sends the header. Only affects direct API calls or integration tests.

### Related Documentation

- [[Epic 2 — Backend API]] § Carry-Forward Blockers
- [[API_Contract]] § Authentication

---

## Summary Table

| Blocker | Priority | Status | Blocks | Est. Fix Time |
|---------|----------|--------|--------|---------------|
| EXTRACT-CONFIG | HIGH | OPEN | Epic 3 testing | 1–2 hours (after proxy/cookie solution chosen) |
| AUTH-FIX | LOW | OPEN | None | 30 minutes |

---

**Last updated:** 2026-04-11  
**Next review:** Sprint 2 kickoff
