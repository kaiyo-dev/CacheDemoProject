# Python Cache Demo

A minimal FastAPI application demonstrating a simple CRUD with SQLite + Redis caching.

## Features
- FastAPI with orjson responses
- Pydantic v2 models
- Async SQLite (aiosqlite)
- Redis cache (redis-py asyncio API)
- Structured logging with loguru
- Basic health endpoint
- Simple item create & fetch with cache layer
- Minimal test using httpx + pytest
- Environment driven configuration

## Project Layout
```
Python/
  requirements.txt
  app/
    main.py
  tests/
    test_health.py
```

## Running Locally
1. Create & activate a virtual environment
2. Install dependencies
3. Run the app

### Quickstart (PowerShell)
```
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install --upgrade pip
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

Visit: http://127.0.0.1:8000/health

## Running Tests
```
pytest -q
```

## Environment Variables
- `REDIS_URL` (default `redis://localhost:6379/0`)
- `DB_PATH` (default `:memory:` uses in-memory SQLite)

## Notes
If Redis is not running, item endpoints will raise connection errors; for quick tests you can start a local redis container:
```
docker run -p 6379:6379 redis:7-alpine
```
