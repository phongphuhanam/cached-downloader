#!/bin/bash

set -euo pipefail

START_IMAGE=${1:-}
if [[ -z "$START_IMAGE" ]]; then
  echo "Usage: $0 <base_image> [username] [container_name] [build|run] [docker_run_extra...]"
  exit 1
fi

BUILD_NAME="${START_IMAGE}.nvim"
USERNAME="${2:-dev}"
DOCKER_NAME="${3:-python_dev}"
START_CMD="/bin/bash"
MODE="${4:-run}"
EXTRA_OPTS=("${@:5}")

ROOT_DIR="/home/$USERNAME"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# $BUILD_NAME is a locally-layered dev image, not something published to a
# registry, so there's nothing to pull.
build_image() {
  echo "[INFO] Building Docker image: $BUILD_NAME"
  pushd "$SCRIPT_DIR"
  if docker buildx version >/dev/null 2>&1; then
    docker buildx build --network=host -f Dockerfile.nvim -t "$BUILD_NAME" \
      --build-arg=BASE_IMAGE="$START_IMAGE" \
      --build-arg=USER_NAME="$USERNAME" \
      .
  else
    echo "[INFO] buildx not available, falling back to classic docker build"
    docker build --network=host -f Dockerfile.nvim -t "$BUILD_NAME" \
      --build-arg=BASE_IMAGE="$START_IMAGE" \
      --build-arg=USER_NAME="$USERNAME" \
      .
  fi
  popd
}

# This script only creates images/containers -- it doesn't manage running
# ones. `build` mode (re)builds the image and stops there; reconnect to an
# already-running container with `docker exec` directly, not by re-running
# this script.
if [[ "$MODE" == "build" ]]; then
  build_image
  exit 0
fi

# Resolve any name conflict up front, before spending time on a build: if a
# container with this name already exists (running or stopped), ask before
# replacing it rather than silently attaching, recreating it out from under
# extra run flags, or erroring after an otherwise-wasted rebuild.
if docker ps -a --format '{{.Names}}' | grep -qx "$DOCKER_NAME"; then
  if [[ "$(docker inspect -f '{{.State.Running}}' "$DOCKER_NAME")" == "true" ]]; then
    echo "[WARN] Container '$DOCKER_NAME' is already running."
  else
    echo "[WARN] Container '$DOCKER_NAME' already exists (stopped)."
  fi
  read -r -p "Stop and remove it, then build/start a new one? [y/N] " REPLY
  if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    docker rm -f "$DOCKER_NAME" >/dev/null
    echo "[INFO] Removed existing container: $DOCKER_NAME"
  else
    echo "[ERROR] Aborting. Reconnect with: docker exec -it $DOCKER_NAME /bin/zsh" >&2
    echo "        (start it first if it's stopped: docker start $DOCKER_NAME)" >&2
    exit 1
  fi
fi

if ! docker image inspect "$BUILD_NAME" >/dev/null 2>&1; then
  build_image
else
  echo "[INFO] Reusing existing image: $BUILD_NAME"
fi

echo "[INFO] Preparing container:"
echo "  Container name : $DOCKER_NAME"
echo "  Base image     : $BUILD_NAME"
echo "  Mount home dir : $ROOT_DIR"
echo "  Entry command  : $START_CMD"

# Ensure persistent volume for container home directory
CACHE_DIR=".cache/$DOCKER_NAME"
mkdir -p "$CACHE_DIR"
HOMEDIR=$(realpath "$CACHE_DIR")

# Update .gitignore safely
grep -qxF ".cache/" .gitignore 2>/dev/null || echo ".cache/" >> .gitignore
grep -qxF "./tmp/" .gitignore 2>/dev/null || echo "./tmp/" >> .gitignore

# Mount the current directory at the same path inside the container, so
# paths (and things like editor jump-to-file) match on both sides.
DOCKER_RUN_OPTS=(-v "$HOMEDIR:$ROOT_DIR:rw" -v "$PWD:$PWD" -w "$PWD" \
  --env=TERM=xterm-256color --env=QT_X11_NO_MITSHM=1)

# Optional: add DISPLAY/X11 setup here if needed in future

echo "[INFO] Starting Docker container: $DOCKER_NAME"
docker run --init -it "${DOCKER_RUN_OPTS[@]}" "${EXTRA_OPTS[@]}" \
  --name="$DOCKER_NAME" \
  --user "$(id -u):$(id -g)" \
  "$BUILD_NAME" "$START_CMD"
