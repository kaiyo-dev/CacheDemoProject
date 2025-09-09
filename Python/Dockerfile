# Multi-stage Dockerfile for FastAPI app
FROM python:3.12-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    POETRY_VIRTUALENVS_CREATE=false

WORKDIR /app

# System deps (sqlite, build tools for any wheels)
RUN apt-get update && apt-get install -y --no-install-recommends build-essential curl && rm -rf /var/lib/apt/lists/*

# Copy dependency files first (layer caching)
COPY pyproject.toml requirements.txt ./

# Install dependencies (prefer requirements.txt for speed; fall back to pyproject)
RUN pip install --upgrade pip && \
    if [ -f requirements.txt ]; then pip install -r requirements.txt; fi

# Copy app source
COPY app ./app

# Add a non-root user
RUN useradd -u 1000 appuser && chown -R appuser /app
USER appuser

EXPOSE 8000

ENV REDIS_URL=redis://redis:6379/0 \
    DB_PATH=/app/data/app.db

# Create data directory with proper permissions
RUN mkdir -p /app/data && chmod 700 /app/data

# Use uvicorn with auto-reload disabled for prod
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
