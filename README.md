# Fedora Phosh Surface - BlueBuild Recipe

A bootc-compatible Fedora Atomic image featuring the Phosh mobile shell, optimized for Microsoft Surface tablets using the linux-surface kernel.

## Features

- **Surface Kernel**: Uses BlueBuild's akmods module with `base: surface` for clean kernel replacement without conflicts
- **Phosh Shell**: Full mobile-optimized GNOME experience with touch-first interface
- **IPTSD Support**: Intel Precision Touch & Stylus Daemon for Surface pen/touch
- **Wayland-first**: Modern display stack with phoc compositor
- **Atomic Updates**: Based on Fedora bootc for reliable, transactional updates

## Building Locally

### Prerequisites

Install BlueBuild CLI:
```bash
bash <(curl -s https://raw.githubusercontent.com/blue-build/cli/main/install.sh)
```

Or using podman:
```bash
podman run --pull always --rm ghcr.io/blue-build/cli:latest-installer | bash
```

### Build the Image

```bash
cd surface-phosh-bluebuild
bluebuild build recipes/fedora-phosh-surface.yml
```

### Build with Podman directly

```bash
bluebuild generate -o Containerfile recipes/fedora-phosh-surface.yml
podman build -t fedora-phosh-surface:latest .
```

## GitHub Actions CI/CD

Create `.github/workflows/build.yml`:

```yaml
name: BlueBuild
on:
  schedule:
    - cron: "00 17 * * *"
  push:
    paths-ignore:
      - "**.md"
  pull_request:
  workflow_dispatch:

jobs:
  bluebuild:
    name: Build Custom Image
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      id-token: write
    strategy:
      fail-fast: false
      matrix:
        recipe:
          - fedora-phosh-surface.yml
    steps:
      - name: Build Custom Image
        uses: blue-build/github-action@v1
        with:
          recipe: ${{ matrix.recipe }}
          cosign_private_key: ${{ secrets.SIGNING_SECRET }}
          registry_token: ${{ github.token }}
          pr_event_number: ${{ github.event.number }}
```

## Installing on a Surface Device

### From existing Fedora Atomic installation

```bash
# Rebase to the image (replace with your registry path)
sudo bootc switch ghcr.io/YOUR_USERNAME/fedora-phosh-surface:latest
sudo reboot
```

### Fresh installation

1. Build an ISO using `bluebuild generate-iso`
2. Write to USB drive
3. Boot Surface from USB (hold Volume Down while pressing Power)
4. Follow installation prompts

## Configuration

### Display Scaling

Edit `/etc/phosh/phoc.ini` to adjust scaling for your Surface model:
- Surface Pro 7/8/9: `scale = 2.0` (default)
- Surface Go: `scale = 1.5`
- Surface Pro 4/5/6: `scale = 2.0`

### Troubleshooting

**Touch not working:**
```bash
sudo systemctl status iptsd
journalctl -u iptsd -f
```

**GDM not starting Phosh:**
```bash
ls -la /usr/share/wayland-sessions/
sudo systemctl status gdm
```

## Module Reference

This recipe uses the following BlueBuild modules:

| Module | Purpose |
|--------|---------|
| `akmods` | Installs Surface kernel cleanly via Universal Blue's infrastructure |
| `dnf` | Modern package installation (replaces rpm-ostree module) |
| `files` | Copies configuration files to the image |
| `script` | Runs custom Phosh configuration script |
| `systemd` | Enables/disables system services |
| `default-flatpaks` | Configures Flatpak and installs mobile-friendly apps |
| `initramfs` | Regenerates initramfs for the Surface kernel |

## Why BlueBuild over raw Containerfile?

The original Containerfile approach had several issues:
1. Multiple kernel subdirectories causing `bootc container lint` failures
2. Complex kernel replacement logic that didn't clean up properly
3. Difficult to maintain procedural build steps

BlueBuild's declarative approach:
- `akmods` module handles kernel replacement atomically
- No leftover kernel module directories
- Built-in bootc validation
- Easier to read, maintain, and version control

## License

MIT License - Feel free to use and modify for your own Surface devices.
