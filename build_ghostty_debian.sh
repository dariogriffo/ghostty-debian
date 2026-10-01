#!/bin/bash
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
declare -a arr=("trixie" "forky" "sid")
for i in "${arr[@]}"
do
  DEBIAN_DIST=$i
  # --network=host: podman's private networking can't resolve DNS for zig's
  # dependency fetcher. Also works for docker.
  docker build . -t ghostty-$DEBIAN_DIST --network=host \
    --secret id=apt_auth,env=APT_AUTH \
    --build-arg GHOSTTY_VERSION=$GHOSTTY_VERSION \
    --build-arg DEBIAN_DIST=$DEBIAN_DIST \
    --build-arg BUILD_VERSION=$BUILD_VERSION
  id="$(docker create ghostty-$DEBIAN_DIST)"
  docker cp $id:/build/ ./output-$DEBIAN_DIST/
  docker rm $id
  # Collect artifacts
  mv ./output-$DEBIAN_DIST/ghostty_*.deb ./
  mv ./output-$DEBIAN_DIST/ghostty-dbgsym_*.deb ./
  mv ./output-$DEBIAN_DIST/libghostty-vt0_*.deb ./output-$DEBIAN_DIST/libghostty-vt-dev_*.deb ./
  rm -rf ./output-$DEBIAN_DIST
done
