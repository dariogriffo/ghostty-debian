![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/dariogriffo/ghostty-debian/total)
![GitHub Downloads (all assets, latest release)](https://img.shields.io/github/downloads/dariogriffo/ghostty-debian/latest/total)
![GitHub Release](https://img.shields.io/github/v/release/dariogriffo/ghostty-debian)
![GitHub Release Date](https://img.shields.io/github/release-date/dariogriffo/ghostty-debian)

<h1>
   <p align="center">
     <a href="https://ghostty.org/"><img src="https://github.com/dariogriffo/ghostty-debian/blob/main/ghostty-logo.png" alt="Ghostty Logo" width="128" style="margin-right: 20px"></a>
     <a href="https://www.debian.org/"><img src="https://github.com/dariogriffo/ghostty-debian/blob/main/debian-logo.png" alt="Debian Logo" width="104" style="margin-left: 20px"></a>
     <br>Ghostty for Debian
   </p>
</h1>
<p align="center">
 👻 Ghostty is a fast, feature-rich, and cross-platform terminal emulator that uses platform-native UI and GPU acceleration.
</p>

<p align="center">
⭐⭐⭐ Love using Ghostty on Debian? Show your support by starring this repo! ⭐⭐⭐
</p>

<h4 align="center">
    <p>
      <a href="https://github.com/dariogriffo/zig-debian">
        <img src="https://avatars.githubusercontent.com/u/27973237?s=200&v=4" alt="Zig Logo" width="48" style="margin-right: 12px">
        <img src="https://www.debian.org/logos/openlogo-nd.svg" alt="Debian Logo" width="39" style="margin-left: 12px">
        <br>Zig for Debian
      </a>
    </p>
</h4>
<p align="center">
  <i>Ghostty is built using Zig, a powerful systems programming language. Check out my Debian package for Zig above.</i>
</p>

# Ghostty for Debian

This repository contains build scripts to produce the _unofficial_ Debian packages
(.deb) for [Ghostty](https://ghostty.org) hosted at [debian.griffo.io](https://debian.griffo.io)

Currently supported debian distros are:
- Bookworm
- Trixie
- Sid

This is an unofficial community project to provide a package that's easy to
install on Debian. If you're looking for the Ghostty source code, see
[ghostty-org/ghostty](https://github.com/ghostty-org/ghostty).

## Install/Update

### The Debian way

```sh
curl -sS https://debian.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/debian.griffo.io.gpg
echo "deb https://debian.griffo.io/apt $(lsb_release -sc 2>/dev/null) main" | sudo tee /etc/apt/sources.list.d/debian.griffo.io.list
sudo apt install ghostty
```

### Manual Installation

1. Download the .deb package for your Debian version available on
   the [Releases](https://github.com/dariogriffo/ghostty-debian/releases) page.
2. Install the downloaded .deb package.

```sh
sudo dpkg -i <filename>.deb
```
## Updating

To update to a new version, just follow any of the installation methods above. There's no need to uninstall the old version; it will be updated correctly.

## Contributing

I want to have an easy-to-install Ghostty package for Debian, so I'm doing what
I can to make it happen. (Ghostty [relies on the
community](https://ghostty.org/docs/install/binary) to produce non-macOS
packages.) I'm sure the scripts I have so far can be improved, so please open an
issue or PR if you notice any problems!

If you want to test locally, you should be able to run
[build_ghostty_debian.sh](https://github.com/dariogriffo/ghostty-debian/blob/main/build_ghostty_debian.sh)
on your own Debian system, only requirement is docker.

## Roadmap

- [x] Produce a .deb package on GitHub Releases
- [x] Set up a debian mirror for easier updates

## Disclaimer

- This repo is not open for issues related to ghostty. This repo is only for _unofficial_ Debian packaging.
- This repository is based on the amazing work of [Mike Kasberg](https://github.com/mkasberg) and his [Ghostty Ubuntu](https://github.com/mkasberg/ghostty-ubuntu) packages
