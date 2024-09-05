#!/bin/bash

#set -x

DOWNLOAD_URL=$1
DOWNLOAD_LOC=$2
CACHE_SERVER_LOC=${CACHE_SERVER_LOC:-"http://localhost:7575/download"}

curl --silent --show-error --fail -X POST $CACHE_SERVER_LOC -H 'Content-Type: application/x-www-form-urlencoded' -d "file_name=$DOWNLOAD_URL" --output $DOWNLOAD_LOC

status=$?

if [ $status -ne 0 ]; then
  echo "Failed cache retrieval. Try downloading again from the original source."
  curl --silent --show-error --fail -L $DOWNLOAD_URL --output $DOWNLOAD_LOC
fi


