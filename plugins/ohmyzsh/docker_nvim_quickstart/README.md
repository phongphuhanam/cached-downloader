# docker_nvim_quickstart

An Oh My Zsh plugin that drops a Neovim + zsh dev environment on top of **any local Docker image**, from whatever project directory you're in — `dnvim python:3.11`, `dnvim node:20`, `dnvim ubuntu:22.04`, etc. Built on top of [cached-downloader](../../..) so tool installs are cached across rebuilds instead of re-fetched from the internet every time.

## Features

- **One command, any base image**: `dnvim <image>` builds the nvim layer on top of `<image>` the first time, then reuses it — no manual Dockerfile per project.
- **Attach, don't recreate**: re-running `dnvim` in a project you already started attaches to the existing container instead of failing on a name conflict.
- **Same-path project mount**: the current directory is mounted inside the container at the identical path (`-v $PWD:$PWD -w $PWD`), so absolute paths, jump-to-file, and tool output line up on both sides.
- **Arch-aware toolchain**: Node, Neovim, ripgrep, fd, and yq are each fetched for the host's actual architecture (`amd64`/`arm64`) at build time — same Dockerfile works unmodified on an x86_64 workstation or an arm64 box (e.g. Jetson).
- **Works with plain `docker build` or `docker buildx`**: the wrapper script detects `buildx` and uses it, falling back to classic `docker build --network=host` otherwise. Native builds only — no QEMU/cross-arch emulation involved.
- **Tab completion**: `dnvim <TAB>` lists local Docker images the same way `docker run <TAB>` does; `dnvim rm <TAB>` completes running/stopped container names.
- **Faster rebuilds**: apt packages are cached via `apt-cacher-ng` (see the parent repo's `docker-compose.yml`) so a base-image bump doesn't force a full re-download of every `.deb`.
- **No baked-in credentials**: `gh` CLI was deliberately left out of the toolchain — using it from inside a container means passing a GitHub token or config onto whatever machine runs the container, which is a real exposure if that machine is remote or shared. Use SSH-based git auth (mount `~/.ssh` or forward an agent) instead.

## Prerequisites

- **Oh My Zsh** — [Installation guide](https://ohmyz.sh/#install)
- **Docker** — with `buildx` available if you want it used automatically (falls back to classic `docker build` otherwise)
- *(optional)* **apt-cacher-ng** running at `localhost:3142` — `docker compose up apt-cacher-ng` from the [cached-downloader](../../..) repo root, to speed up apt package fetches across rebuilds

### Verify Prerequisites

```bash
docker version
docker buildx version   # optional
```

## Installation

```bash
cd plugins/ohmyzsh/docker_nvim_quickstart
./install.sh
```

Symlinks this directory into `${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/docker_nvim_quickstart/` (so edits to `Dockerfile.nvim`, `start_docker_nvim.sh`, etc. take effect immediately, no re-install needed) and adds `docker_nvim_quickstart` to `plugins=(...)` in `~/.zshrc`.

Reload your shell:

```bash
source ~/.zshrc
```

Use `./install.sh --copy` instead if you want a standalone, decoupled copy — e.g. distributing this plugin apart from this repo, where a dangling symlink to a deleted checkout would break it.

## Usage

### Start (or attach to) a dev container

```bash
dnvim <image> [username]
```

Builds the `<image>.nvim` layer if it doesn't exist yet (reused on every later call), then runs or attaches to a container named after the current project directory + image, with the project directory mounted at the same path inside the container.

**Example:**
```bash
cd ~/projects/my-app
dnvim python:3.11
# -> builds python:3.11.nvim (first time only)
# -> runs container "my-app_python_3.11", mounted at the same path
# re-run the same command later in the same directory: attaches instead of erroring
```

### Force a rebuild

```bash
dnvim rebuild <image>
```

Rebuilds the nvim layer for `<image>` even if it already exists locally — use this after changing `Dockerfile.nvim` or to pick up newer pinned tool versions.

### List built images

```bash
dnvim ls
```

Lists every locally-built `*.nvim` image.

### Remove a dev container

```bash
dnvim rm <container-name>
```

`<container-name>` tab-completes from `docker ps -a`.

## How It Works

1. `dnvim` derives a container name from the current directory's basename + the image name (sanitized), so different projects — or the same project against different base images — don't collide.
2. It checks whether `<image>.nvim` already exists locally (`docker image inspect`); if not, it builds it via `start_docker_nvim.sh`, which uses `docker buildx build --network=host` when buildx is available, or falls back to classic `docker build --network=host`.
3. If a container with that derived name already exists, it's started (if stopped) and attached to (`docker exec -it ... /bin/zsh`) instead of re-running `docker run`, which would otherwise fail with a name conflict.
4. Otherwise, a new container is started with the project directory bind-mounted at the same path (`-v $PWD:$PWD -w $PWD`) and a persistent home directory (`.cache/<container-name>/` on the host, mounted as `$HOME` in the container) so shell history, installed nvim plugins, etc. survive container restarts.
5. Inside the image, `Dockerfile.nvim` installs Node, Neovim, ripgrep, fd, yq, and rclone, each resolved to the correct architecture via `dpkg --print-architecture` at build time (not `ARG TARGETARCH`, which only BuildKit populates — this way the same Dockerfile behaves identically under plain `docker build` and `buildx`).

### Architecture handling

| Tool | amd64 asset | arm64 asset | Install method |
|---|---|---|---|
| Node.js | `linux-x64.tar.gz` | `linux-arm64.tar.gz` | tarball |
| Neovim | `nvim-linux-x86_64.tar.gz` | `nvim-linux-arm64.tar.gz` | tarball |
| ripgrep | `..._amd64.deb` | *(no arm64 `.deb`)* `...-aarch64-unknown-linux-gnu.tar.gz` | `.deb` on amd64, raw binary extracted from tarball on arm64 |
| fd | `..._amd64.deb` | `..._arm64.deb` | `.deb` |
| yq | `yq_linux_amd64` | `yq_linux_arm64` | raw binary |
| rclone | `...-linux-amd64.deb` | `...-linux-arm64.deb` | `.deb` |

Only native builds are supported (whatever architecture the build actually runs on) — no `--platform`/QEMU cross-building.

## Prerequisites for Base Images

`Dockerfile.nvim` assumes a Debian/Ubuntu-family base image (it uses `apt-get`/`dpkg`). Anything else (Alpine, etc.) isn't supported without changes.

## Troubleshooting

### "docker: command not found"

Install Docker: https://docs.docker.com/engine/install/

### `dnvim: can't find start_docker_nvim.sh`

The plugin locates its supporting scripts relative to its own file path. If you see this, either `install.sh` didn't finish copying all the files, or `$DOCKER_NVIM_HOME` was set explicitly to the wrong directory — unset it or point it at the plugin's install directory.

### Rebuild picks up nothing new

`dnvim <image>` reuses the existing `<image>.nvim` image once it's built. Use `dnvim rebuild <image>` to force a fresh build (e.g. after editing `Dockerfile.nvim`).

### apt package installs are slow on every rebuild

Start `apt-cacher-ng` (`docker compose up apt-cacher-ng` from the [cached-downloader](../../..) repo root) before building — `Dockerfile.nvim` auto-detects it at `localhost:3142` and uses it if reachable, falling back to a direct connection otherwise.

## Security Considerations

- **No `gh` CLI in the image**: avoids the choice between copying a GitHub token onto the container's host or leaving the container unauthenticated. If you need `gh`, install it ad hoc inside a running container rather than baking it (and a token) into the image.
- **rclone is included but unconfigured**: pass credentials at `docker run` time via `RCLONE_CONFIG_<REMOTE>_*` environment variables (see `rclone config providers`/`rclone obscure`) rather than baking a `rclone.conf` into the image or the persistent per-container home volume — that way nothing sensitive travels with the image or `.cache/` if it's ever copied to another machine.
- **Persistent home volume**: `.cache/<container-name>/` (mounted as `$HOME`) persists shell state, nvim plugins, and anything else written under `$HOME` across container restarts — including any secrets you configure interactively inside the container. Treat it like any other local credential store.

## License

Covered by the parent repository's license.
