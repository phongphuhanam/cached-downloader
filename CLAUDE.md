# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project does

A caching download proxy service. Clients POST a URL to the Flask server; the server downloads and caches the file locally using the `minato` library, then returns it as an attachment. On a cache hit, the file is served immediately without re-downloading.

`cached_download.sh` is the client-side helper: it POSTs to the cache server and falls back to a direct download if the server is unavailable.

## Running the service

**With Docker Compose (recommended):**
```bash
docker compose up --build       # first run
docker compose up               # subsequent runs
docker compose down
```
The server listens on `http://localhost:7575`. The cache volume is `.cached/` → `/data/` inside the container.

**Directly (dev mode):**
```bash
pip install flask loguru minato
FLASK_APP=main_app.py flask run --host=0.0.0.0   # port 5000
```

## Using the client script

```bash
# Uses CACHE_SERVER_LOC env var (default: http://localhost:7575/download)
./cached_download.sh <URL> <output-path>

# Point at a remote server
CACHE_SERVER_LOC=http://myserver:7575/download ./cached_download.sh <URL> <output-path>
```

## Environment variables

| Variable | Default | Description |
|---|---|---|
| `CACHED_LOCATION` | `.cached/` (local) / `/data/` (Docker) | Where files are cached on disk |
| `AUTO_UPDATE` | `0` | Re-download if remote file changed |
| `FORCE_DOWNLOAD` | `0` | Always re-download regardless of cache |
| `EXPIRE_DAYS` | `-1` (never) | Evict cached files older than N days |
| `CACHE_SERVER_LOC` | `http://localhost:7575/download` | Cache server URL (client script only) |

## Architecture

- **`main_app.py`** — Single Flask app with one route (`POST /download`). Delegates all caching logic to `minato.cached_path()`. Returns the cached file via `send_from_directory`.
- **`cached_download.sh`** — Thin curl wrapper. Falls back to direct download (`curl -L`) if the cache server returns a non-zero exit.
- **`Dockerfile`** / **`docker-compose.yml`** — Alpine-based image; port mapping is `7575:5000`.

There are no tests and no linting configuration in this repository.
