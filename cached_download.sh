#!/bin/bash

set -x

DOWNLOAD_URL=$1
DOWNLOAD_LOC=$2
IS_PIPE=${IS_PIPE:-"none"}
CACHE_SERVER_LOC=${CACHE_SERVER_LOC:-"http://localhost:7575/download"}

DOWNLOAD_COMMAND="-H 'Content-Type: application/x-www-form-urlencoded'"
DOWNLOAD_COMMAND+=" -d \"file_name=$DOWNLOAD_URL\""

download() {
  if ( "$IS_PIPE" == "pipe" ); then
    curl --silent --show-error --fail -L $DOWNLOAD_COMMAND | $DOWNLOAD_LOC
  else:
    curl --silent --show-error --fail -L $DOWNLOAD_COMMAND $DOWNLOAD_LOC
  fi
}

download $IS_PIPE $DOWNLOAD_COMMAND $DOWNLOAD_LOC 
#curl --silent --show-error --fail -X POST $CACHE_SERVER_LOC -H 'Content-Type: application/x-www-form-urlencoded' -d "file_name=$DOWNLOAD_URL" $DOWNLOAD_LOC

status=$?

if [ $status -ne 0 ]; then
  echo "Failed cache retrieval. Try downloading again from the original source."
  curl --silent --show-error --fail -L $DOWNLOAD_URL $DOWNLOAD_LOC
fi


