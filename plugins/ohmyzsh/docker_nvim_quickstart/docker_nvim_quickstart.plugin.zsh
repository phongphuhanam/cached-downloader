#!/usr/bin/env zsh
# docker_nvim_quickstart.plugin.zsh
# Oh My Zsh plugin: create a Neovim + zsh dev container layered on top of
# any local Docker image, from whatever project directory you're in.
#
# dnvim only creates images/containers -- it does not manage running ones.
# Reconnect to an already-created container with `docker exec` directly.
#
# Backed by start_docker_nvim.sh / Dockerfile.nvim next to this file (found
# via the current script path, so this still works once this file is
# copied or symlinked into $ZSH_CUSTOM/plugins/docker_nvim_quickstart/).
#
# See README.md for usage. Tab completion lives in _docker_nvim_quickstart
# (loaded automatically by Oh My Zsh alongside this file).

# Verify Docker is available
if ! command -v docker &> /dev/null; then
  echo "Warning: docker not found. docker_nvim_quickstart requires the Docker CLI to be installed."
  return 1
fi

DOCKER_NVIM_HOME="${DOCKER_NVIM_HOME:-${${(%):-%x}:A:h}}"

dnvim() {
  emulate -L zsh

  if [[ ! -x "$DOCKER_NVIM_HOME/start_docker_nvim.sh" ]]; then
    echo "dnvim: can't find start_docker_nvim.sh under $DOCKER_NVIM_HOME (set \$DOCKER_NVIM_HOME)" >&2
    return 1
  fi

  case "${1:-}" in
    ""|-h|--help)
      echo "usage: dnvim <image> [username] [-- <docker run args>]" >&2
      echo "       dnvim rebuild <image> | dnvim ls | dnvim rm <container-name>" >&2
      return 1
      ;;
    ls)
      docker images --format '{{.Repository}}:{{.Tag}}' | grep '\.nvim$'
      return
      ;;
    rm)
      local name="${2:?usage: dnvim rm <container-name>}"
      docker rm -f "$name"
      return
      ;;
    rebuild)
      local image="${2:?usage: dnvim rebuild <image>}"
      # Rebuilds the image only -- does not touch any container.
      _dnvim_run "$image" build dev
      return
      ;;
  esac

  local image="$1"
  shift
  local username="dev"
  # A second positional that isn't "--" is the username; "--" (with nothing
  # or a username already consumed before it) introduces raw docker flags.
  if [[ "${1:-}" != "--" && -n "${1:-}" ]]; then
    username="$1"
    shift
  fi
  [[ "${1:-}" == "--" ]] && shift
  _dnvim_run "$image" run "$username" "$@"
}

_dnvim_run() {
  local image="$1" mode="$2" username="$3"
  shift 3
  # Derive the container name from project dir + image so different
  # projects (or the same project against different base images) don't
  # collide. dnvim only creates -- it errors if this name already exists
  # rather than attaching or recreating it (see start_docker_nvim.sh).
  local safe_image="${image//[:\/]/_}"
  local container_name="${PWD:t}_${safe_image}"

  "$DOCKER_NVIM_HOME/start_docker_nvim.sh" "$image" "$username" "$container_name" "$mode" "$@"
}

# Completion helpers shared with _docker_nvim_quickstart (mirrors
# `docker run <TAB>`: local image names for the image argument, container
# names for `dnvim rm`). Delegate to Docker's own completion helpers when
# the `docker` plugin/CLI completion is loaded (exact match to `docker
# run`'s own candidate list), falling back to a plain `docker images`/
# `docker ps` listing otherwise.
_dnvim_images() {
  if (( $+functions[__docker_complete_images] )); then
    __docker_complete_images
  else
    local -a images
    images=(${(f)"$(docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep -v '\.nvim$')"})
    _describe -t docker-images 'docker image' images
  fi
}

_dnvim_containers() {
  if (( $+functions[__docker_complete_containers_names] )); then
    __docker_complete_containers_names
  else
    local -a containers
    containers=(${(f)"$(docker ps -a --format '{{.Names}}' 2>/dev/null)"})
    _describe -t docker-containers 'container' containers
  fi
}
