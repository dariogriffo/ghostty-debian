#!/bin/bash
set -euo pipefail

GHOSTTY_VERSION=$1
BUILD_VERSION=$2

if [ -z "$GHOSTTY_VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <ghostty_version> <build_version>"
    echo "Example: $0 1.1.3 1"
    exit 1
fi

PACKAGE_NAME="ghostty"
ORIG_TARBALL="${PACKAGE_NAME}_${GHOSTTY_VERSION}.orig.tar.gz"
BUILD_DIR="${PACKAGE_NAME}-${GHOSTTY_VERSION}"

echo "Creating Debian source packages for ghostty ${GHOSTTY_VERSION}-${BUILD_VERSION}..."

# Download upstream source tarball (shared .orig.tar.gz across all distributions)
if [ ! -f "$ORIG_TARBALL" ]; then
    echo "Downloading upstream source from GitHub..."
    wget -q "https://github.com/ghostty-org/ghostty/archive/refs/tags/v${GHOSTTY_VERSION}.tar.gz" -O "$ORIG_TARBALL"
    echo "  Downloaded $ORIG_TARBALL"
else
    echo "  Using existing $ORIG_TARBALL"
fi

build_source_package() {
    local dist=$1
    local FULL_VERSION="${GHOSTTY_VERSION}-${BUILD_VERSION}~${dist}"

    echo "  Building source package for ${dist} (${FULL_VERSION})..."

    # Clean and recreate build directory from orig tarball
    rm -rf "$BUILD_DIR"
    tar -xf "$ORIG_TARBALL"
    # GitHub archives extract as ghostty-1.x.y/ which matches our BUILD_DIR

    # Copy Debian packaging directory
    cp -r debian "$BUILD_DIR/"

    # Generate distribution-specific changelog (overwrites placeholder)
    cat > "$BUILD_DIR/debian/changelog" << EOF
ghostty (${FULL_VERSION}) ${dist}; urgency=medium

  * New upstream release ${GHOSTTY_VERSION}.

 -- Dario Griffo <dariogriffo@gmail.com>  $(date -R)
EOF

    # Build source package (.dsc + .debian.tar.xz); reuses existing .orig.tar.gz
    dpkg-source -b "$BUILD_DIR"

    rm -rf "$BUILD_DIR"
    echo "    ${FULL_VERSION}"
}

echo ""
echo "Building Debian source packages..."
DEBIAN_DISTS=("trixie" "forky" "sid")
for dist in "${DEBIAN_DISTS[@]}"; do
    build_source_package "$dist"
done

UBUNTU_DISTS=()

echo ""
echo "Source packages created successfully!"
echo ""
echo "Generated files:"
ls -la "${PACKAGE_NAME}_"*.dsc "${PACKAGE_NAME}_"*.orig.tar.gz "${PACKAGE_NAME}_"*.debian.tar.xz 2>/dev/null || true
