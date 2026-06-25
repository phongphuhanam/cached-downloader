#!/bin/bash

#set -x

DOWNLOAD_URL=$1
DESTINATION=$2
CACHE_SERVER_LOC=${CACHE_SERVER_LOC:-"http://localhost:7575/download"}

case "$DOWNLOAD_URL" in
  *.tar.gz|*.tgz)    TAR_FLAGS="-xz" ;;
  *.tar.bz2|*.tbz2)  TAR_FLAGS="-xj" ;;
  *.tar.xz|*.txz)    TAR_FLAGS="-xJ" ;;
  *.tar.zst)          TAR_FLAGS="-x --zstd" ;;
  *.tar)              TAR_FLAGS="-x" ;;
  *)
    echo "Unsupported archive format: $DOWNLOAD_URL" >&2
    exit 1
    ;;
esac

mkdir -p "$DESTINATION"

curl --silent --show-error --fail -X POST "$CACHE_SERVER_LOC" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "file_name=$DOWNLOAD_URL" | tar $TAR_FLAGS -C "$DESTINATION"

CURL_STATUS=${PIPESTATUS[0]}
TAR_STATUS=${PIPESTATUS[1]}

if [ $CURL_STATUS -ne 0 ] || [ $TAR_STATUS -ne 0 ]; then
  echo "Failed cache retrieval. Downloading directly from source." >&2
  curl --silent --show-error --fail -L "$DOWNLOAD_URL" | tar $TAR_FLAGS -C "$DESTINATION"
fi
