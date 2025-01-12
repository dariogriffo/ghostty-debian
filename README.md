
![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/dariogriffo/ghostty-debian/total)
![GitHub Downloads (all assets, latest release)](https://img.shields.io/github/downloads/dariogriffo/ghostty-debian/latest/total)
![GitHub Release](https://img.shields.io/github/v/release/dariogriffo/ghostty-debian)
![GitHub Release Date](https://img.shields.io/github/release-date/dariogriffo/ghostty-debian)

![Ghostty Logo](ghostty-logo.png)

# Ghostty Debian

This repository contains build scripts to produce an _unofficial_ Debian package
(.deb) for [Ghostty](https://ghostty.org).

This is an unofficial community project to provide a package that's easy to
install on Debian. If you're looking for the Ghostty source code, see
[ghostty-org/ghostty](https://github.com/ghostty-org/ghostty).

## Install/Update

> [!WARNING]
> A recent GTK is required for Ghostty to work with Nvidia (GL) drivers under
> X11. **Debian 22.04 LTS has GTK 4.6 which is not new enough.** Debian 23.10+ should be fine. (See the
> [note](https://ghostty.org/docs/install/build#debian-and-debian) in the
> Ghostty docs.)

## Manual Installation

1. Download the .deb package for your Debian version. (Also available on the [Releases](https://github.com/dariogriffo/ghostty-debian/releases) page.)
   - **Debian bookworm:** [ghostty_1.0.1-1.bookworm_amd64.deb](https://github.com/dariogriffo/ghostty-debian/releases/download/1.0.1/ghostty_1.0.1-1.bookworm_amd64.deb)
   - **Debian trixie:** [ghostty_1.0.1-1.trixie_amd64.deb](https://github.com/dariogriffo/ghostty-debian/releases/download/1.0.1/ghostty_1.0.1-1.trixie_amd64.deb)
   - **Debian sid:** [ghostty_1.0.1-1.sid_amd64.deb](https://github.com/dariogriffo/ghostty-debian/releases/download/1.0.1/ghostty_1.0.1-1.sid_amd64.deb)
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

GitHub Actions will run CI on each PR to test that we can produce a build.

If you want to test locally, you should be able to run
[build_ghostty_debian.sh](https://github.com/dariogriffo/ghostty-debian/blob/main/build_ghostty_debian.sh)
on your own Debian system, only requirement is docker.

## Roadmap

- [x] Produce a .deb package on GitHub Releases
- [ ] Set up a debian mirror for easier updates

## Disclaimer

This repository is based on the amazing work of [Mike Kasberg](https://github.com/mkasberg) and his [Ghostty Ubuntu](https://github.com/mkasberg/ghostty-ubuntu) packages
