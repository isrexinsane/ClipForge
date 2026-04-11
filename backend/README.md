# ClipForge Backend

Video extraction service for ClipForge — a social media video-to-GIF creation app for iOS.

## Setup

### Prerequisites

- Docker (recommended) or Python 3.12+
- ffmpeg (installed automatically in Docker)

### Build the Docker Image

```bash
docker build -t clipforge-api ./backend
```

### Run Locally

```bash
docker run -p 8000:8000 -e CLIPFORGE_API_KEY=cf_live_test clipforge-api
```

### Test the Health Endpoint

```bash
curl http://localhost:8000/v1/health
```

Expected response:

```json
{
  "status": "ok",
  "yt_dlp_version": "2026.3.17",
  "supported_platforms": ["twitter", "instagram", "reddit", "tiktok", "twitch"],
  "uptime_seconds": 5
}
```

### API Documentation

With the server running, visit:

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

### Environment Variables

See `.env.example` for all configuration options.
