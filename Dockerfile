# syntax=docker/dockerfile:1
# One build for every suite, on the oldest one ghostty still supports: the
# libraries it links against keep their names and only get newer on forky,
# sid, questing and resolute, so a trixie build installs on all of them.
FROM debian:trixie

ARG GHOSTTY_VERSION
ARG BUILD_VERSION

# Install build deps + packaging tools
# APT::Immediate-Configure=false works around a dependency-ordering bug in
# sid's tpm2-tss/systemd-tpm stack (libtss2-tcti-cmd0t64 fails to configure)
# No blueprint-compiler here: we build from the upstream release tarball, which
# ships the pre-generated gresource files (trixie only has 0.16, ghostty needs
# >= 0.20 when building from a git checkout).
RUN apt-get update && apt-get install -y -o APT::Immediate-Configure=false \
    curl wget gpg lsb-release \
    build-essential debhelper devscripts fakeroot \
    pandoc minisign \
    libonig-dev libbz2-dev libgtk4-layer-shell-dev \
    libgtk-4-dev libadwaita-1-dev libxml2-utils libfontconfig-dev

# Install zig from griffo.io repo. Ghostty needs zig >= 0.16 from 1.4.0 on
# (minimum_zig_version in build.zig.zon); zig-stable is 0.17 now and builds it.
# The repo requires credentials; they arrive as a BuildKit secret mounted only
# for this RUN, so they never land in a layer, the image history or a build arg.
RUN --mount=type=secret,id=apt_auth,target=/etc/apt/auth.conf.d/deb.griffo.io.conf,mode=0600,required=true \
    curl -sS https://deb.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc \
    | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/deb.griffo.io.gpg \
    && echo "deb https://deb.griffo.io/apt $(lsb_release -sc) main" \
    | tee /etc/apt/sources.list.d/deb.griffo.io.list \
    && apt-get update \
    && apt-get install -y zig-stable

# Fetch the upstream release tarball and verify its minisign signature.
# The public key is published in ghostty's PACKAGING.md.
WORKDIR /build
RUN wget -q "https://release.files.ghostty.org/${GHOSTTY_VERSION}/ghostty-${GHOSTTY_VERSION}.tar.gz" \
    && wget -q "https://release.files.ghostty.org/${GHOSTTY_VERSION}/ghostty-${GHOSTTY_VERSION}.tar.gz.minisig" \
    && minisign -Vm "ghostty-${GHOSTTY_VERSION}.tar.gz" \
        -P RWQlAjJC23149WL2sEpT/l0QKy7hMIFhYdQOFy0Z7z7PbneUgvlsnYcV \
    && tar -xzmf "ghostty-${GHOSTTY_VERSION}.tar.gz" \
    && rm "ghostty-${GHOSTTY_VERSION}.tar.gz" "ghostty-${GHOSTTY_VERSION}.tar.gz.minisig"

WORKDIR /build/ghostty-$GHOSTTY_VERSION

# Copy debian packaging
COPY debian/ debian/
RUN chmod +x debian/rules

# Generate debian/changelog with proper version and timestamp. The fixed
# ~griffo tag replaces ~<suite>: the ~ keeps it below a distro's own build of
# the same version, and the apt repo links the one file into every suite.
ENV DEBEMAIL="dariogriffo@gmail.com"
ENV DEBFULLNAME="Dario Griffo"
RUN rm -f debian/changelog && \
    dch --create --package ghostty \
    --newversion "${GHOSTTY_VERSION}-${BUILD_VERSION}~griffo" \
    --distribution stable \
    "Unofficial Debian package." && \
    dch --append "https://ghostty.org/docs/install/release-notes/$(echo $GHOSTTY_VERSION | tr '.' '-')"

# Build
RUN dpkg-buildpackage --build=binary --no-sign --no-check-builddeps

