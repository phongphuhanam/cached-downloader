# cached-downloader

A caching download proxy for Docker builds. When an earlier Dockerfile layer changes, Docker invalidates all subsequent layers — forcing files to be re-downloaded even if they haven't changed. This service caches downloads locally so subsequent builds fetch from the cache instead of the internet.

## Running the server

```bash
docker compose up --build   # first run
docker compose up           # subsequent runs
```

The server listens on `http://localhost:7575`. Downloaded files are stored in `.cached/`.

## Client scripts

### `cached_download.sh` — download a file

```bash
./cached_download.sh <URL> <output-path>
```

### `cached_unpack.sh` — download and extract an archive on the fly

```bash
./cached_unpack.sh <URL> <destination-dir>
```

Streams the archive directly into the destination without writing a temporary file first. Supports `.tar.gz`, `.tgz`, `.tar.bz2`, `.tbz2`, `.tar.xz`, `.txz`, `.tar.zst`, and `.tar`.

Both scripts fall back to a direct download if the cache server is unavailable.

### Dockerfile usage

```dockerfile
ADD https://raw.githubusercontent.com/phongphuhanam/cached-downloader/main/cached_download.sh /usr/bin/cached_download
ADD https://raw.githubusercontent.com/phongphuhanam/cached-downloader/main/cached_unpack.sh /usr/bin/cached_unpack
ENV CACHE_SERVER_LOC=http://cache-host:7575/download

RUN cached_download https://example.com/model.bin /opt/model.bin
RUN cached_unpack https://example.com/tools.tar.gz /opt/tools/
```

## Environment variables

| Variable | Default | Description |
|---|---|---|
| `CACHE_SERVER_LOC` | `http://localhost:7575/download` | Cache server URL (client scripts) |
| `CACHED_LOCATION` | `/data/` (Docker) | Where files are cached on disk (server) |
| `AUTO_UPDATE` | `0` | Re-download if remote file changed |
| `FORCE_DOWNLOAD` | `0` | Always re-download regardless of cache |
| `EXPIRE_DAYS` | `-1` (never) | Evict cached files older than N days |
