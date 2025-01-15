GHOSTTY_VERSION=$1
BUILD_VERSION=$2
declare -a arr=("bookworm" "trixie" "sid")
for i in "${arr[@]}"
do
  DEBIAN_DIST=$i
  FULL_VERSION=$GHOSTTY_VERSION-${BUILD_VERSION}+${DEBIAN_DIST}_amd64
  docker build . -t ghostty-$DEBIAN_DIST --build-arg GHOSTTY_VERSION=$GHOSTTY_VERSION --build-arg DEBIAN_DIST=$DEBIAN_DIST --build-arg BUILD_VERSION=$BUILD_VERSION --build-arg FULL_VERSION=$FULL_VERSION
  id="$(docker create ghostty-$DEBIAN_DIST)"
  docker cp $id:/ghostty_$FULL_VERSION.deb - > ./ghostty_$FULL_VERSION.deb
  tar -xf ./ghostty_$FULL_VERSION.deb
done

