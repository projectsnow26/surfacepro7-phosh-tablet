# Fedora Phosh Surface

[![Build and Push](https://github.com/YOUR_USERNAME/fedora-phosh-surface/actions/workflows/build.yml/badge.svg)](https://github.com/YOUR_USERNAME/fedora-phosh-surface/actions/workflows/build.yml)

An immutable Fedora bootc image with Phosh (mobile shell) optimized for Microsoft Surface Pro 7, designed as a media entertainment and DJ workstation.

## Features

- **Phosh Desktop**: Touch-optimized mobile shell for tablet use
- **linux-surface Kernel**: Full hardware support for Surface Pro 7
  - Touchscreen and pen (via iptsd)
  - Cameras
  - WiFi/Bluetooth
  - Power management
- **Media Entertainment**: Pre-configured for streaming services
  - Firefox with Widevine DRM (Netflix, Disney+, etc.)
  - Spotify Flatpak
  - Plex, VLC, and more
- **DJ Workstation**: Mixxx with controller support
  - Numark Mixtrack Platinum FX ready
  - Low-latency audio via PipeWire
  - Realtime audio permissions

## Quick Start

### Option 1: Use Pre-built Image

```bash
# Generate ISO with your user credentials
cat > config.toml << 'EOF'
[[customizations.user]]
name = "dj"
password = "changeme"
groups = ["wheel"]
EOF

# Build ISO
sudo podman run --rm -it --privileged \
  -v ./config.toml:/config.toml:ro \
  -v ./output:/output \
  quay.io/centos-bootc/bootc-image-builder:latest \
  --type iso --rootfs ext4 --config /config.toml \
  ghcr.io/YOUR_USERNAME/fedora-phosh-surface:latest
```

### Option 2: Build Your Own

1. Fork this repository
2. Add signing secrets (see Setup Guide)
3. Push changes to trigger build
4. Generate ISO from your image

## Hardware Requirements

- Microsoft Surface Pro 7 (tested)
- Other Surface devices may work with linux-surface support

## Included Software

### Desktop Environment
- Phosh (mobile shell)
- Phoc (Wayland compositor)
- Squeekboard (on-screen keyboard)
- GNOME applications (Files, Settings, etc.)

### Media & Streaming
- Firefox (DRM-enabled)
- Chromium (Flatpak, for PWAs)
- Spotify (Flatpak)
- VLC (Flatpak)
- Plex (Flatpak)

### DJ Software
- Mixxx (Flatpak)
- PipeWire + JACK

### System
- NetworkManager
- Bluetooth
- Power Profiles Daemon
- Firmware updater (fwupd)

## Updates

The system uses atomic bootc updates:

```bash
# Check for updates
sudo bootc upgrade --check

# Apply updates
sudo bootc upgrade
sudo reboot

# Rollback if needed
sudo bootc rollback
sudo reboot
```

## Documentation

See [COMPLETE-SETUP-GUIDE.md](COMPLETE-SETUP-GUIDE.md) for detailed instructions.

## License

MIT License - See LICENSE file

## Credits

- [linux-surface](https://github.com/linux-surface/linux-surface) - Surface hardware support
- [Phosh](https://phosh.mobi/) - Mobile shell
- [Fedora bootc](https://docs.fedoraproject.org/en-US/bootc/) - Base image
- [BlueBuild](https://blue-build.org/) - Inspiration for the build approach
