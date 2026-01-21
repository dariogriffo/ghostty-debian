ARG DEBIAN_DIST=bookworm
FROM debian:$DEBIAN_DIST

ARG DEBIAN_DIST
ARG GHOSTTY_VERSION
ARG BUILD_VERSION
ARG FULL_VERSION

RUN apt update && apt install -y git curl wget gpg blueprint-compiler git build-essential debhelper devscripts pandoc libonig-dev libbz2-dev libgtk4-layer-shell-dev libgtk-4-dev libadwaita-1-dev minisign libxml2-utils
RUN wget https://github.com/dariogriffo/zig-debian/releases/download/0.14.1%2B9/zig-zero_0.14.1-9+bookworm_amd64.deb && apt install ./zig-zero_0.14.1-9+bookworm_amd64.deb && ln -s /usr/lib/zig/0.14.1/zig /usr/bin/zig

RUN git clone https://github.com/ghostty-org/ghostty
WORKDIR "ghostty" 
RUN git checkout v$GHOSTTY_VERSION

RUN sed -i 's|https://github.com/mbadolato/iTerm2-Color-Schemes/releases/download/release-20251002-142451-4a5043e/ghostty-themes.tgz|https://github.com/mbadolato/iTerm2-Color-Schemes/releases/download/release-20251229-150532-f279991/ghostty-themes.tgz|' build.zig.zon
RUN sed -i 's|N-V-__8AALIsAwDyo88G5mGJGN2lSVmmFMx4YePfUvp_2o3Y|N-V-__8AAIdIAwAO4ro1DOaG7QTFq3ewrTQIViIKJ3lKY6lV|' build.zig.zon
RUN sed -i 's/linkSystemLibrary2("bzip2", dynamic_link_opts)/linkSystemLibrary2("bz2", dynamic_link_opts)/' build.zig
RUN zig build --summary all --prefix ./zig-out/usr -Doptimize=ReleaseFast -Dcpu=baseline -Dpie=true -Demit-docs -Dversion-string=$GHOSTTY_VERSION


RUN mkdir -p /output/DEBIAN
RUN mkdir -p /output/usr/share/doc/ghostty/

COPY output/DEBIAN/control /output/DEBIAN/
COPY output/changelog.Debian /output/usr/share/doc/ghostty/changelog.Debian
COPY output/copyright /output/usr/share/doc/ghostty/copyright

RUN cp -R ./zig-out/** /output/

RUN sed -i "s/DIST/$DEBIAN_DIST/" /output/usr/share/doc/ghostty/changelog.Debian
RUN sed -i "s/DIST/$DEBIAN_DIST/" /output/DEBIAN/control
RUN sed -i "s/GHOSTTY_VERSION/$GHOSTTY_VERSION/" /output/DEBIAN/control
RUN sed -i "s/BUILD_VERSION/$BUILD_VERSION/" /output/DEBIAN/control

RUN sed -i 's/\.\/zig-out//g' /output/usr/share/systemd/user/app-com.mitchellh.ghostty.service
RUN sed -i 's/\.\/zig-out//g' /output/usr/share/applications/com.mitchellh.ghostty.desktop
RUN sed -i 's/\.\/zig-out//g' /output/usr/share/dbus-1/services/com.mitchellh.ghostty.service

RUN gzip -n -9 /output/usr/share/doc/ghostty/changelog.Debian

RUN gzip -n -9 /output/usr/share/man/man1/ghostty.1
RUN gzip -n -9 /output/usr/share/man/man5/ghostty.5
RUN mv /output/usr/share/zsh/site-functions /output/usr/share/zsh/vendor-completions
RUN rm -fRd /output/usr/share/terminfo/g || true

RUN ls -la /output/*
RUN dpkg-deb --build /output /ghostty_${FULL_VERSION}.deb