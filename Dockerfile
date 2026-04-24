ARG DEBIAN_DIST=trixie
FROM debian:$DEBIAN_DIST

ARG DEBIAN_DIST
ARG GHOSTTY_VERSION
ARG BUILD_VERSION

# Install build deps + packaging tools
RUN apt-get update && apt-get install -y \
    git curl wget gpg lsb-release \
    build-essential debhelper devscripts fakeroot \
    blueprint-compiler pandoc minisign \
    libonig-dev libbz2-dev libgtk4-layer-shell-dev \
    libgtk-4-dev libadwaita-1-dev libxml2-utils

# Install zig from griffo.io repo
RUN curl -sS https://debian.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc \
    | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/debian.griffo.io.gpg \
    && echo "deb https://debian.griffo.io/apt $(lsb_release -sc) main" \
    | tee /etc/apt/sources.list.d/debian.griffo.io.list \
    && apt-get update \
    && apt-get install -y zig-oldstable

# Clone and checkout
WORKDIR /build
RUN git clone https://github.com/ghostty-org/ghostty
WORKDIR /build/ghostty
RUN git checkout v$GHOSTTY_VERSION

# Copy debian packaging
COPY debian/ debian/
RUN chmod +x debian/rules

# Generate debian/changelog with proper version and timestamp
ENV DEBEMAIL="dariogriffo@gmail.com"
ENV DEBFULLNAME="Dario Griffo"
RUN dch --create --package ghostty \
    --newversion "${GHOSTTY_VERSION}-${BUILD_VERSION}+${DEBIAN_DIST}" \
    --distribution "${DEBIAN_DIST}" \
    "Unofficial Debian package." && \
    dch --append "https://ghostty.org/docs/install/release-notes/$(echo $GHOSTTY_VERSION | tr '.' '-')"

# Build
RUN dpkg-buildpackage --build=binary --no-sign --no-check-builddeps

