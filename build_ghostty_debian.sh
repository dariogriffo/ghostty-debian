docker build . -t ghostty-bookworm --build-arg GHOSTTY_VERSION=1.0.1 --build-arg DEBIAN_DIST=bookworm
id=$(docker create ghostty-bookworm)
docker cp $id:/ghostty_1.0.1-1~bookworm_amd64.deb - > ./ghostty_1.0.1-1~bookworm_amd64.deb
tar -xf ./ghostty_1.0.1-1~bookworm_amd64.deb


docker build . -t ghostty-trixie --build-arg GHOSTTY_VERSION=1.0.1 --build-arg DEBIAN_DIST=trixie
id=$(docker create ghostty-trixie)
docker cp $id:/ghostty_1.0.1-1~trixie_amd64.deb - > ./ghostty_1.0.1-1~trixie_amd64.deb
tar -xf ./ghostty_1.0.1-1~trixie_amd64.deb

docker build . -t ghostty-sid --build-arg GHOSTTY_VERSION=1.0.1 --build-arg DEBIAN_DIST=sid
id=$(docker create ghostty-sid)
docker cp $id:/ghostty_1.0.1-1~sid_amd64.deb - > ./ghostty_1.0.1-1~sid_amd64.deb
tar -xf ./ghostty_1.0.1-1~sid_amd64.deb

