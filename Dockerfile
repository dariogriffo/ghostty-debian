ARG DEBIAN_DIST=bookworm
FROM debian:$DEBIAN_DIST

ARG DEBIAN_DIST
ARG GHOSTTY_VERSION
ARG BUILD_VERSION
ARG FULL_VERSION

RUN apt update && apt install -y git curl gpg
RUN curl -sS https://debian.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/debian.griffo.io.gpg
RUN echo "deb https://debian.griffo.io/apt $DEBIAN_DIST main" | tee /etc/apt/sources.list.d/debian.griffo.io.list

RUN apt update && apt install -y blueprint-compiler zig git build-essential debhelper devscripts pandoc libonig-dev libbz2-dev wget libgtk4-layer-shell-dev libgtk-4-dev libadwaita-1-dev minisign
RUN git clone https://github.com/ghostty-org/ghostty
WORKDIR "ghostty" 

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

RUN gzip -n -9 /output/usr/share/doc/ghostty/changelog.Debian

RUN gzip -n -9 /output/usr/share/man/man1/ghostty.1
RUN gzip -n -9 /output/usr/share/man/man5/ghostty.5
RUN mv /output/usr/share/zsh/site-functions /output/usr/share/zsh/vendor-completions
RUN [ "$DEBIAN_DIST" != "bookworm" ] && rm -fRd /output/usr/share/terminfo/g || true

RUN ls -la /output/*
RUN dpkg-deb --build /output /ghostty_${FULL_VERSION}.deb


