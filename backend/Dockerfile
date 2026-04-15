FROM python:3.12-slim

# Install ffmpeg — required by yt-dlp for video processing
RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies first (layer caching)
COPY requirements.txt .
# --pre allows installing yt-dlp nightly builds (dev releases)
RUN pip install --no-cache-dir --pre -r requirements.txt

# Copy application code
COPY app/ app/

EXPOSE 8000

# Run FastAPI via Uvicorn
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
