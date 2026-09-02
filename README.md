# cached-downloader

A caching download proxy for Docker builds. When an earlier Dockerfile layer changes, Docker invalidates all subsequent layers — forcing files to be re-downloaded even if they haven't changed. This service caches downloads locally so subsequent builds fetch from the cache instead of the internet.

## Running the server

```bash
docker compose up --build   # first run
docker compose up           # subsequent runs
```

The server listens on `http://localhost:7575`. Downloaded files are stored in `.cached/`.

`docker compose up` also starts an **`apt-cacher-ng`** service (port `3142`, cache in `.apt-cache/`) for Debian-family image builds: it caches `apt-get install` package fetches the same way this service caches URL downloads, so a base-image bump doesn't force re-downloading every `.deb`. It's optional — a build only uses it if it's reachable; see [`plugins/ohmyzsh/docker_nvim_quickstart`](plugins/ohmyzsh/docker_nvim_quickstart) for a Dockerfile that wires it in.

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
ENV CACHE_SERVER_LOC=http://localhost:7575/download

RUN cached_download https://example.com/model.bin /opt/model.bin
RUN cached_unpack https://example.com/tools.tar.gz /opt/tools/
```

If the cache server runs on the same machine as the build, use `--network=host` so the build container can reach `localhost:7575`:

```bash
docker build --network=host -t myimage .
```

## Environment variables

| Variable | Default | Description |
|---|---|---|
| `CACHE_SERVER_LOC` | `http://localhost:7575/download` | Cache server URL (client scripts) |
| `CACHED_LOCATION` | `/data/` (Docker) | Where files are cached on disk (server) |
| `AUTO_UPDATE` | `0` | Re-download if remote file changed |
| `FORCE_DOWNLOAD` | `0` | Always re-download regardless of cache |
| `EXPIRE_DAYS` | `-1` (never) | Evict cached files older than N days |

## Example: a full dev container built on this

[`plugins/ohmyzsh/docker_nvim_quickstart`](plugins/ohmyzsh/docker_nvim_quickstart) is an Oh My Zsh plugin (`dnvim <image>`) that layers a Neovim + zsh dev environment on top of any local Docker image, using `cached_download` for every tool install (Node, Neovim, ripgrep, fd, yq, rclone) and `apt-cacher-ng` for the underlying `apt-get install`. It's a good end-to-end reference for using both caches together in a real Dockerfile.
