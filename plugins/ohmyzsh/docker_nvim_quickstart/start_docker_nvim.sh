#!/bin/bash

set -euo pipefail

START_IMAGE=${1:-}
if [[ -z "$START_IMAGE" ]]; then
  echo "Usage: $0 <base_image> [username] [container_name] [build|run] [docker_run_extra]"
  exit 1
fi

BUILD_NAME="${START_IMAGE}.nvim"
USERNAME="${2:-dev}"
DOCKER_NAME="${3:-python_dev}"
START_CMD="/bin/bash"
MODE="${4:-run}"
EXTRA_OPTS="${5:-}"

ROOT_DIR="/home/$USERNAME"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# $BUILD_NAME is a locally-layered dev image, not something published to a
# registry, so there's nothing to pull. Build it once per (base image, user)
# pair and reuse the local image on every later call unless a rebuild is
# explicitly requested (MODE=build) or it isn't built yet.
if [[ "$MODE" == "build" ]] || ! docker image inspect "$BUILD_NAME" >/dev/null 2>&1; then
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

# Re-run against a container that already exists (same name = same project +
# base image) instead of failing on a name conflict: attach to it directly.
if docker ps -a --format '{{.Names}}' | grep -qx "$DOCKER_NAME"; then
  if [[ "$(docker inspect -f '{{.State.Running}}' "$DOCKER_NAME")" != "true" ]]; then
    echo "[INFO] Starting existing stopped container: $DOCKER_NAME"
    docker start "$DOCKER_NAME" >/dev/null
  fi
  echo "[INFO] Attaching to container: $DOCKER_NAME"
  exec docker exec -it "$DOCKER_NAME" /bin/zsh
fi

# Mount the current directory at the same path inside the container, so
# paths (and things like editor jump-to-file) match on both sides.
DOCKER_RUN_OPTS="-v $HOMEDIR:$ROOT_DIR:rw"
DOCKER_RUN_OPTS+=" -v $PWD:$PWD -w $PWD"
DOCKER_RUN_OPTS+=" --env=TERM=xterm-256color --env=QT_X11_NO_MITSHM=1"
DOCKER_RUN_OPTS+=" $EXTRA_OPTS"

# Optional: add DISPLAY/X11 setup here if needed in future

echo "[INFO] Starting Docker container: $DOCKER_NAME"
docker run --init -it $DOCKER_RUN_OPTS \
  --name="$DOCKER_NAME" \
  --user "$(id -u):$(id -g)" \
  "$BUILD_NAME" "$START_CMD"
