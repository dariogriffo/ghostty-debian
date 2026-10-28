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

echo "Creating Debian/Ubuntu source packages for ghostty ${GHOSTTY_VERSION}-${BUILD_VERSION}..."

# A rebuild of an upstream version already released here (a +N build bump)
# must ship the very same orig tarball: the pool holds one per upstream
# version and reprepro refuses a different one, and nothing guarantees the
# archive download is byte-identical next time. Reuse the earlier release's copy.
if [ ! -f "$ORIG_TARBALL" ]; then
    for ((b = BUILD_VERSION - 1; b >= 1; b--)); do
        if wget -q "https://github.com/dariogriffo/ghostty-debian/releases/download/${GHOSTTY_VERSION}%2B${b}/${ORIG_TARBALL}" -O "$ORIG_TARBALL"; then
            echo "  Reusing $ORIG_TARBALL from release ${GHOSTTY_VERSION}+${b}"
            break
        fi
        rm -f "$ORIG_TARBALL"
    done
fi

# Download upstream source tarball (shared .orig.tar.gz across all distributions)
if [ ! -f "$ORIG_TARBALL" ]; then
    echo "Downloading upstream source from GitHub..."
    wget -q "https://github.com/ghostty-org/ghostty/archive/refs/tags/v${GHOSTTY_VERSION}.tar.gz" -O "$ORIG_TARBALL"
    echo "  Downloaded $ORIG_TARBALL"
else
    echo "  Using existing $ORIG_TARBALL"
fi

build_source_package() {
    local FULL_VERSION="${GHOSTTY_VERSION}-${BUILD_VERSION}~griffo"

    echo "  Building source package ${FULL_VERSION}..."

    # Clean and recreate build directory from orig tarball
    rm -rf "$BUILD_DIR"
    tar -xf "$ORIG_TARBALL"
    # GitHub archives extract as ghostty-1.x.y/ which matches our BUILD_DIR

    # Copy Debian packaging directory
    cp -r debian "$BUILD_DIR/"

    # Generate the changelog (overwrites placeholder)
    cat > "$BUILD_DIR/debian/changelog" << EOF
ghostty (${FULL_VERSION}) stable; urgency=medium

  * New upstream release ${GHOSTTY_VERSION}.

 -- Dario Griffo <dariogriffo@gmail.com>  $(date -R)
EOF

    # Build source package (.dsc + .debian.tar.xz); reuses existing .orig.tar.gz
    dpkg-source -b "$BUILD_DIR"

    rm -rf "$BUILD_DIR"
    echo "    ${FULL_VERSION}"
}

echo ""
# One source package for every suite, as with the binaries (see the Dockerfile).
build_source_package

echo ""
echo "Source packages created successfully!"
echo ""
echo "Generated files:"
ls -la "${PACKAGE_NAME}_"*.dsc "${PACKAGE_NAME}_"*.orig.tar.gz "${PACKAGE_NAME}_"*.debian.tar.xz 2>/dev/null || true
