#!/bin/bash
GHOSTTY_VERSION=$1
BUILD_VERSION=$2
declare -a arr=("trixie" "forky" "sid")
for i in "${arr[@]}"
do
  DEBIAN_DIST=$i
  # --network=host: podman's private networking can't resolve DNS for zig's
  # dependency fetcher. Also works for docker.
  docker build . -t ghostty-$DEBIAN_DIST --network=host \
    --build-arg GHOSTTY_VERSION=$GHOSTTY_VERSION \
    --build-arg DEBIAN_DIST=$DEBIAN_DIST \
    --build-arg BUILD_VERSION=$BUILD_VERSION
  id="$(docker create ghostty-$DEBIAN_DIST)"
  docker cp $id:/build/ ./output-$DEBIAN_DIST/
  docker rm $id
  # Collect artifacts
  mv ./output-$DEBIAN_DIST/ghostty_*.deb ./
  mv ./output-$DEBIAN_DIST/ghostty-dbgsym_*.deb ./
  rm -rf ./output-$DEBIAN_DIST
done
