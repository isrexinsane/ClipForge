"""
ClipForge Backend — FastAPI application entry point.

This is the main application module. It creates the FastAPI instance,
includes routers, and configures middleware. Run via Uvicorn:

    uvicorn app.main:app --host 0.0.0.0 --port 8000
"""

import asyncio
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from slowapi.errors import RateLimitExceeded

from app.cleanup import cleanup_loop
from app.extraction import TEMP_DIR
from app.routers import extract, health, media


# ---------------------------------------------------------------------------
# Lifespan — startup / shutdown logic
# ---------------------------------------------------------------------------


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Manage background tasks across the app's lifetime."""
    # Ensure temp directory exists on startup
    TEMP_DIR.mkdir(parents=True, exist_ok=True)

    # Start the background cleanup task
    cleanup_task = asyncio.create_task(cleanup_loop())
    yield
    # Shutdown: cancel the cleanup task
    cleanup_task.cancel()
    try:
        await cleanup_task
    except asyncio.CancelledError:
        pass


# ---------------------------------------------------------------------------
# App instance
# ---------------------------------------------------------------------------

app = FastAPI(
    title="ClipForge API",
    description="Backend extraction service for ClipForge — social media video-to-GIF creation.",
    version="0.1.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)


# ---------------------------------------------------------------------------
# Rate limiting error handler
# ---------------------------------------------------------------------------


@app.exception_handler(RateLimitExceeded)
async def rate_limit_handler(request: Request, exc: RateLimitExceeded) -> JSONResponse:
    """Return a 429 with our standard error JSON and a Retry-After header."""
    retry_after = getattr(exc, "retry_after", 60)
    return JSONResponse(
        status_code=429,
        content={
            "error": "RATE_LIMITED",
            "detail": "Rate limit exceeded. Please wait before trying again.",
        },
        headers={"Retry-After": str(retry_after)},
    )


# ---------------------------------------------------------------------------
# Mount routers
# ---------------------------------------------------------------------------

app.include_router(health.router)
app.include_router(extract.router)
app.include_router(media.router)

# Add the limiter state to the app so slowapi can access it
app.state.limiter = extract.limiter
