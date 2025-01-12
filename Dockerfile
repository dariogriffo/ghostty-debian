ARG DEBIAN_DIST=bookworm
FROM debian:$DEBIAN_DIST

ARG DEBIAN_DIST
ARG GHOSTTY_VERSION

RUN mkdir ghosty

ENV ZIG_VERSION=0.13.0
ENV RELEASE_VERSION=1
ENV FULL_VERSION=$GHOSTTY_VERSION-${RELEASE_VERSION}~${DEBIAN_DIST}_amd64


RUN apt update && apt install -y build-essential debhelper devscripts pandoc libonig-dev libbz2-dev wget libgtk-4-dev libadwaita-1-dev minisign


RUN wget -q "https://ziglang.org/download/$ZIG_VERSION/zig-linux-x86_64-$ZIG_VERSION.tar.xz" && tar -xf "zig-linux-x86_64-$ZIG_VERSION.tar.xz" -C /opt && rm "zig-linux-x86_64-$ZIG_VERSION.tar.xz" && ln -s "/opt/zig-linux-x86_64-$ZIG_VERSION/zig" /usr/local/bin/zig

RUN wget -q "https://release.files.ghostty.org/$GHOSTTY_VERSION/ghostty-$GHOSTTY_VERSION.tar.gz"
RUN wget -q "https://release.files.ghostty.org/$GHOSTTY_VERSION/ghostty-$GHOSTTY_VERSION.tar.gz.minisig"

RUN minisign -Vm "ghostty-$GHOSTTY_VERSION.tar.gz" -P RWQlAjJC23149WL2sEpT/l0QKy7hMIFhYdQOFy0Z7z7PbneUgvlsnYcV

RUN rm ghostty-$GHOSTTY_VERSION.tar.gz.minisig
RUN tar -xzmf "ghostty-$GHOSTTY_VERSION.tar.gz"

WORKDIR "ghostty-$GHOSTTY_VERSION" 

RUN sed -i 's/linkSystemLibrary2("bzip2", dynamic_link_opts)/linkSystemLibrary2("bz2", dynamic_link_opts)/' build.zig
RUN zig build --summary all --prefix ./zig-out/usr -Doptimize=ReleaseFast -Dcpu=baseline -Dpie=true -Demit-docs -Dversion-string=$GHOSTTY_VERSION


RUN mkdir -p /output/DEBIAN

COPY output/DEBIAN/control /output/DEBIAN/
COPY output/changelog.Debian /output/changelog.Debian
COPY output/copyright /output/copyright

RUN cp -R ./zig-out/** /output/

RUN sed -i "s/DIST/$DEBIAN_DIST/" /output/changelog.Debian

RUN mkdir -p /output/usr/share/doc/ghostty/
RUN cp /output/copyright /output/usr/share/doc/ghostty/
RUN cp /output/changelog.Debian /output/usr/share/doc/ghostty/

RUN gzip -n -9 /output/usr/share/doc/ghostty/changelog.Debian

RUN gzip -n -9 /output/usr/share/man/man1/ghostty.1
RUN gzip -n -9 /output/usr/share/man/man5/ghostty.5
RUN mv /output/usr/share/zsh/site-functions /output/usr/share/zsh/vendor-completions

RUN ls -la /output/*
RUN dpkg-deb --build /output /ghostty_${FULL_VERSION}.deb


