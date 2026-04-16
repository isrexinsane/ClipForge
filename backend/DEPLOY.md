# Deploying ClipForge Backend to Railway

This guide walks through deploying the ClipForge backend to Railway from scratch. It assumes zero DevOps experience. The whole process takes about 10 minutes.

## What You'll Need

- A GitHub account (you probably already have one)
- A Railway account (free to create, ~$5/month for this service)
- The ClipForge repo pushed to GitHub

## Step 1: Push the Code to GitHub

If you haven't already, create a GitHub repository and push the ClipForge project:

```bash
cd "ClipForge - iOS App Development"
git init
git add .
git commit -m "Initial commit: ClipForge iOS app + backend"
git remote add origin https://github.com/YOUR_USERNAME/clipforge.git
git branch -M main
git push -u origin main
```

## Step 2: Create a Railway Account

1. Go to [railway.com](https://railway.com) and click **Sign Up**
2. Sign in with your GitHub account (this makes deployment easier)
3. Add a payment method in Settings → Billing (the Hobby plan is $5/month with $5 of included usage — more than enough for ClipForge)

## Step 3: Create a New Project on Railway

1. From the Railway dashboard, click **New Project**
2. Select **Deploy from GitHub repo**
3. Find and select your ClipForge repository
4. Railway will detect the `backend/` directory — if it asks which directory to deploy, select `backend/`
5. If Railway doesn't auto-detect the directory, you'll configure it in the next step

## Step 4: Configure the Service

In the Railway service settings:

1. Click on the service that was created
2. Go to **Settings** tab
3. Under **Source**, set the **Root Directory** to `backend` (this tells Railway to build from the backend folder, not the repo root)
4. Under **Build**, Railway should auto-detect the Dockerfile. If not, set the builder to "Dockerfile"
5. Under **Networking**, click **Generate Domain** — this creates your public HTTPS URL (something like `clipforge-api-production.up.railway.app`)

## Step 5: Set Environment Variables

1. In the Railway service, go to the **Variables** tab
2. Click **New Variable** and add:

| Variable | Value | Notes |
|----------|-------|-------|
| `CLIPFORGE_API_KEY` | `cf_live_` followed by a random string | Generate one: open Ghostty and run `python3 -c "import secrets; print('cf_live_' + secrets.token_hex(24))"` |
| `PORT` | `8000` | Railway sets this automatically, but explicit is safer |

**Save the API key somewhere secure** (e.g., Apple Notes or a password manager). The iOS app will need it later.

## Step 6: Deploy

Railway auto-deploys when you push to GitHub. For the first deploy:

1. Railway should start building automatically after you configure the service
2. Watch the **Deployments** tab — you'll see the Docker build logs in real time
3. The build takes 2-3 minutes (downloading Python, installing ffmpeg, installing pip packages)
4. When the status shows **Active**, your backend is live

## Step 7: Verify the Deployment

Open Ghostty (or any terminal) and run these commands. Replace `YOUR_DOMAIN` with the domain Railway generated (e.g., `clipforge-api-production.up.railway.app`):

### Health check:

```bash
curl https://YOUR_DOMAIN/v1/health
```

Expected output:
```json
{
  "status": "ok",
  "yt_dlp_version": "2026.3.17",
  "supported_platforms": ["twitter", "instagram", "tiktok", "twitch"],
  "uptime_seconds": 42
}
```

### Test extraction (replace YOUR_API_KEY):

```bash
curl -X POST https://YOUR_DOMAIN/v1/extract \
  -H "Content-Type: application/json" \
  -H "X-API-Key: YOUR_API_KEY" \
  -d '{"url": "https://x.com/NASA/status/1871619786259976519"}'
```

Expected: HTTP 200 with video metadata and a `video_url` field.

### Test media retrieval (use the video_url from the previous response):

```bash
curl -o test_video.mp4 "https://YOUR_DOMAIN/v1/media/FILE_ID?token=TOKEN&expires=EXPIRES"
```

Expected: Downloads the video file.

### Test auth rejection:

```bash
curl -X POST https://YOUR_DOMAIN/v1/extract \
  -H "Content-Type: application/json" \
  -d '{"url": "https://x.com/test/status/123"}'
```

Expected: HTTP 422 (missing API key header).

## Deploying Updates

After the initial setup, deploying changes is just a git push:

```bash
git add .
git commit -m "Description of changes"
git push origin main
```

Railway detects the push, rebuilds the Docker image, and deploys automatically. The switchover is zero-downtime (Railway starts the new container before stopping the old one).

### Updating yt-dlp

When yt-dlp releases a new version (check [github.com/yt-dlp/yt-dlp/releases](https://github.com/yt-dlp/yt-dlp/releases)):

1. Edit `backend/requirements.txt` and update the yt-dlp version number
2. Commit and push — Railway auto-deploys with the new version

## Viewing Logs

1. Go to the Railway dashboard
2. Click your ClipForge service
3. Click the **Deployments** tab, then click the active deployment
4. Click **View Logs** — you'll see real-time server output

## Cost

Railway's Hobby plan is $5/month with $5 of included usage. ClipForge's backend is lightweight (idle most of the time, spins up briefly per extraction request), so it should stay well within the $5 allowance. If usage grows, Railway charges per-second for compute above the included amount.

## Troubleshooting

**Build fails:** Check the build logs in the Deployments tab. Common issues: typo in Dockerfile, missing dependency in requirements.txt.

**Health check returns error:** Make sure the Root Directory is set to `backend` in service settings.

**Extraction returns 502:** yt-dlp may need updating. Check if the platform changed their API. Update the version in requirements.txt and push.

**Can't reach the URL:** Make sure you generated a domain in Settings → Networking.
