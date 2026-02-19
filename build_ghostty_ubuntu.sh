GHOSTTY_VERSION=$1
BUILD_VERSION=$2
declare -a arr=("noble")
for i in "${arr[@]}"
do
  UBUNTU_DIST=$i
  FULL_VERSION=$GHOSTTY_VERSION-${BUILD_VERSION}+${UBUNTU_DIST}_amd64_ubu
  docker build . -f Dockerfile.ubu -t ghostty-ubuntu-$UBUNTU_DIST --build-arg GHOSTTY_VERSION=$GHOSTTY_VERSION --build-arg UBUNTU_DIST=$UBUNTU_DIST --build-arg BUILD_VERSION=$BUILD_VERSION --build-arg FULL_VERSION=$FULL_VERSION
  id="$(docker create ghostty-ubuntu-$UBUNTU_DIST)"
  docker cp $id:/ghostty_$FULL_VERSION.deb - > ./ghostty_$FULL_VERSION.deb
  tar -xf ./ghostty_$FULL_VERSION.deb
done
