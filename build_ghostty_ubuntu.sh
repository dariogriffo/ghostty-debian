#!/bin/bash
GHOSTTY_VERSION=$1
BUILD_VERSION=$2
declare -a arr=("noble" "questing" "resolute")
for i in "${arr[@]}"
do
  UBUNTU_DIST=$i
  # --network=host: podman's private networking can't resolve DNS for zig's
  # dependency fetcher. Also works for docker.
  docker build . -f Dockerfile.ubu -t ghostty-$UBUNTU_DIST --network=host \
    --build-arg GHOSTTY_VERSION=$GHOSTTY_VERSION \
    --build-arg UBUNTU_DIST=$UBUNTU_DIST \
    --build-arg BUILD_VERSION=$BUILD_VERSION
  id="$(docker create ghostty-$UBUNTU_DIST)"
  docker cp $id:/output/ ./output-$UBUNTU_DIST/
  docker rm $id
  # Collect artifacts. Releases with a debugedit too old for zig's DWARF
  # (noble) build stripped, so there is no dbgsym package to collect.
  mv ./output-$UBUNTU_DIST/ghostty_*.deb ./
  mv ./output-$UBUNTU_DIST/ghostty-dbgsym_*.deb ./ 2>/dev/null || true
  # _ubu suffix: the apt repo's download_ubuntu_file.sh expects it, and it
  # keeps the Ubuntu assets obvious next to the Debian ones on the release
  for f in ./ghostty*_${UBUNTU_DIST}_*.deb; do
    case "$f" in *_ubu.deb) ;; *) mv "$f" "${f%.deb}_ubu.deb" ;; esac
  done
  rm -rf ./output-$UBUNTU_DIST
done
