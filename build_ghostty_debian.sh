#!/bin/bash
set -euo pipefail
GHOSTTY_VERSION=$1
BUILD_VERSION=$2
# deb.griffo.io needs credentials. Build the apt auth file in memory (printf is
# a builtin, so they never show up in a process list) and hand it to docker as
# a BuildKit secret.
: "${DEB_GRIFFO_LOGIN:?set DEB_GRIFFO_LOGIN to your deb.griffo.io login}"
: "${DEB_GRIFFO_PASSWORD:?set DEB_GRIFFO_PASSWORD to your deb.griffo.io password}"
APT_AUTH=$(printf 'machine deb.griffo.io\nlogin %s\npassword %s\n' \
  "$DEB_GRIFFO_LOGIN" "$DEB_GRIFFO_PASSWORD")
export APT_AUTH
# One build for every Debian and Ubuntu suite (see the Dockerfile), versioned
# <ver>-<build>~griffo.
# --network=host: podman's private networking can't resolve DNS for zig's
# dependency fetcher. Also works for docker.
docker build . -t ghostty --network=host \
  --secret id=apt_auth,env=APT_AUTH \
  --build-arg GHOSTTY_VERSION=$GHOSTTY_VERSION \
  --build-arg BUILD_VERSION=$BUILD_VERSION
id="$(docker create ghostty)"
docker cp $id:/build/ ./output/
docker rm $id
# Collect artifacts
mv ./output/ghostty_*.deb ./
mv ./output/ghostty-dbgsym_*.deb ./
mv ./output/libghostty-vt0_*.deb ./output/libghostty-vt-dev_*.deb ./
rm -rf ./output
