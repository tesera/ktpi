#!/bin/bash -e

FORCE_REBUILD=false
CONTAINER="tesera/ktpi"

usage() { printf "Usage: $0 [-f]\n  -f  Force docker re-build from nothing. (uses docker --no-cache)\n" 1>&2; exit 1; }

while getopts ":fh" opt; do
  case $opt in
    f)
      FORCE_REBUILD=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      exit 1
      ;;
    h)
      usage
      exit 0;
      ;;
  esac
done

if $FORCE_REBUILD; then
    docker build --no-cache -t $CONTAINER .
else
    docker build -t $CONTAINER .
fi
