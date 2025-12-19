# Fedora Phosh Surface Pro 7: Complete Setup Guide

A complete guide for building an immutable Fedora bootc image with Phosh (mobile shell) for Surface Pro 7, configured as a media entertainment and DJ box.

**Target Hardware:** Microsoft Surface Pro 7 (Intel 10th Gen)
**Desktop Environment:** Phosh (touch-optimized mobile shell)
**Use Cases:**
- Streaming media (Netflix, Spotify, YouTube, etc.)
- DJ mixing with Mixxx + Numark Mixtrack Platinum FX

---

## Part 1: Why This Approach?

### Fedora bootc vs CentOS Stream 9

We're using Fedora instead of CentOS Stream 9 because:
- **linux-surface kernel**: Only available for Fedora (f33-f42), not EL9
- **Phosh**: In mainline Fedora repos, would require extensive backporting for CentOS
- **Surface Pro 7 support**: Touch, pen, cameras, sensors all require linux-surface patches

### Why bootc (not rpm-ostree/Silverblue)?

- Simpler container-native workflow
- Standard Containerfile/Podman tooling
- No rpm-ostree specific quirks
- Better for custom kernel integration

### What You Get

| Feature | Implementation |
|---------|----------------|
| Touch UI | Phosh mobile shell |
| Surface hardware | linux-surface kernel + iptsd |
| Streaming apps | Firefox, Chromium (PWAs), Spotify Flatpak |
| DJ software | Mixxx Flatpak |
| Updates | Atomic bootc upgrades |
| Rollback | Instant boot to previous image |

---

## Part 2: Prerequisites

Before starting:

- GitHub account (for container registry)
- Linux machine with Podman (for ISO generation)
- USB drive (8GB+)
- Surface Pro 7
- ~2-3 hours for initial setup

---

## Part 3: Repository Setup

### 3.1 Create GitHub Repository

1. Go to https://github.com/new
2. Name it (e.g., `fedora-phosh-surface`)
3. Make it **Public** (required for free GitHub Actions + GHCR)
4. Initialize with README
5. Click **Create repository**

### 3.2 Clone Locally

```bash
git clone https://github.com/YOUR_USERNAME/fedora-phosh-surface.git
cd fedora-phosh-surface
```

### 3.3 SSH Key Setup (if needed)

```bash
# Generate key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Start agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Copy public key to GitHub Settings → SSH Keys
cat ~/.ssh/id_ed25519.pub

# Switch to SSH remote
git remote set-url origin git@github.com:YOUR_USERNAME/fedora-phosh-surface.git

# Test
ssh -T git@github.com
```

---

## Part 4: Signing Setup

### 4.1 Install Cosign

```bash
sudo curl -sSfL -o /usr/local/bin/cosign \
  https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64
sudo chmod +x /usr/local/bin/cosign
cosign version
```

### 4.2 Generate Key Pair

```bash
cosign generate-key-pair
```

Press Enter for no password (or set one and note it).

### 4.3 Add to GitHub Secrets

1. Go to your repo → **Settings** → **Secrets and variables** → **Actions**
2. Add secret `SIGNING_SECRET` with contents of `cosign.key`
3. If you set a password, add `SIGNING_SECRET_PASSWORD`

### 4.4 Secure the Keys

```bash
# Keep public key
cp cosign.pub ~/cosign-backup.pub

# DELETE private key locally
rm cosign.key
```

---

## Part 5: Project Structure

Create the following structure:

```
fedora-phosh-surface/
├── .github/
│   └── workflows/
│       └── build.yml
├── config/
│   ├── flatpak-apps.txt
│   ├── phosh-favorites.txt
│   └── surface-udev.rules
├── scripts/
│   ├── configure-phosh.sh
│   ├── setup-flatpak.sh
│   └── post-install.sh
├── Containerfile
├── README.md
└── COMPLETE-SETUP-GUIDE.md
```

---

## Part 6: The Containerfile

This is the heart of your build. It creates an immutable Fedora image with:
- Phosh desktop environment
- linux-surface kernel for Surface Pro 7 hardware
- Flatpak support for apps (Mixxx, Spotify, etc.)
- Touch and pen support via iptsd

See `Containerfile` in this repository.

---

## Part 7: GitHub Actions Workflow

The workflow in `.github/workflows/build.yml`:
- Builds the container image on every push
- Publishes to GitHub Container Registry (ghcr.io)
- Signs the image with cosign

---

## Part 8: Commit and Push

```bash
git add .
git commit -m "Initial Fedora Phosh Surface build"
git push origin main
```

Monitor the build at: `https://github.com/YOUR_USERNAME/fedora-phosh-surface/actions`

First build takes **30-60 minutes** (linux-surface kernel is large).

---

## Part 9: Generate Installation ISO

### 9.1 Create User Configuration

Create `config.toml` on your build machine:

```toml
[[customizations.user]]
name = "dj"
password = "changeme"
groups = ["wheel"]
```

### 9.2 Build the ISO

```bash
mkdir -p output

sudo podman run --rm -it --privileged \
  --pull=newer \
  --security-opt label=type:unconfined_t \
  -v ./config.toml:/config.toml:ro \
  -v ./output:/output \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  quay.io/centos-bootc/bootc-image-builder:latest \
  --type iso \
  --rootfs ext4 \
  --config /config.toml \
  ghcr.io/YOUR_USERNAME/fedora-phosh-surface:latest
```

Takes **20-40 minutes**. Output: `output/bootiso/install.iso`

---

## Part 10: Create Bootable USB

### Linux

```bash
# Find USB device
lsblk

# Write ISO (replace sdX)
sudo dd if=output/bootiso/install.iso of=/dev/sdX bs=4M status=progress oflag=sync
sync
```

### Windows

Use [Rufus](https://rufus.ie/) or [balenaEtcher](https://etcher.balena.io/)

---

## Part 11: Install on Surface Pro 7

### 11.1 Prepare Surface

1. Boot into Windows
2. Run Windows Update to get latest firmware
3. In UEFI (hold Volume Up + Power):
   - Disable Secure Boot, OR
   - Enable "Allow Microsoft & 3rd Party UEFI CA"

### 11.2 Boot from USB

1. Shut down Surface
2. Insert USB
3. Hold **Volume Down** + Press **Power**
4. Release when you see the boot menu
5. Select USB drive

### 11.3 Install

1. Select target disk (typically the internal NVMe)
2. Confirm (disk will be erased)
3. Wait for installation (~10 minutes)
4. Remove USB, reboot

### 11.4 First Boot

1. Phosh lock screen appears
2. Enter PIN/password from config.toml
3. **Immediately change password:**

```bash
passwd
```

---

## Part 12: Post-Installation Setup

### 12.1 Connect to WiFi

Tap the top bar → WiFi icon → Select network → Enter password

Or via terminal:
```bash
nmcli device wifi list
nmcli device wifi connect "YourSSID" password "yourpassword"
```

### 12.2 Install Flatpak Apps

The image includes a first-boot script, but you can also run manually:

```bash
# Mixxx (DJ software)
flatpak install -y flathub org.mixxx.Mixxx

# Spotify
flatpak install -y flathub com.spotify.Client

# Firefox (with better codecs)
flatpak install -y flathub org.mozilla.firefox

# Optional: Other streaming apps
flatpak install -y flathub tv.plex.PlexDesktop
flatpak install -y flathub com.stremio.Stremio
```

### 12.3 Verify Hardware

```bash
# Touch/Pen (iptsd should be running)
systemctl status iptsd

# Surface hardware
sudo dmesg | grep -i surface

# Audio
pactl info

# Camera
ls /dev/video*
```

### 12.4 Configure Mixxx for Controller

1. Open Mixxx
2. Options → Preferences → Controllers
3. Your Numark Mixtrack Platinum FX should be detected
4. Select the mapping (built-in or download from Mixxx wiki)

---

## Part 13: System Maintenance

### Updates

```bash
# Check for updates
sudo bootc upgrade --check

# Apply updates
sudo bootc upgrade

# Reboot into new image
sudo reboot
```

### Rollback

```bash
sudo bootc rollback
sudo reboot
```

### Check Status

```bash
sudo bootc status
```

### Push Your Own Updates

1. Edit files in your repo
2. Commit and push
3. Wait for GitHub Actions build
4. Run `sudo bootc upgrade` on Surface

---

## Part 14: Streaming Services

### What Works

| Service | Method | DRM Support |
|---------|--------|-------------|
| Netflix | Firefox/Chromium | ✓ (Widevine) |
| Spotify | Flatpak app | ✓ |
| YouTube | Browser | ✓ |
| Disney+ | Browser | ✓ |
| Amazon Prime | Browser | ✓ |
| Plex | Flatpak app | ✓ |

### Netflix/Disney+ Tips

Firefox and Chromium Flatpaks include Widevine for DRM content. For best results:
- Use Firefox (better touch support)
- Enable hardware acceleration in settings

### PWA Installation

In Chromium/Firefox, you can install web apps:
1. Visit the streaming site
2. Menu → "Install as App" or "Add to Home Screen"

---

## Part 15: Troubleshooting

### Touch Not Working

```bash
# Check iptsd status
systemctl status iptsd
journalctl -u iptsd

# Restart iptsd
sudo systemctl restart iptsd
```

### No WiFi

```bash
# Check if Surface WiFi module loaded
lspci | grep -i network
dmesg | grep -i mwifiex

# Restart NetworkManager
sudo systemctl restart NetworkManager
```

### No Sound

```bash
# Check PipeWire
systemctl --user status pipewire pipewire-pulse

# List audio devices
pactl list sinks short

# Restart audio
systemctl --user restart pipewire pipewire-pulse
```

### Black Screen After Boot

At GRUB, press `e`, add `nomodeset` to kernel line, Ctrl+X to boot. Then:
```bash
journalctl -b | grep -i drm
```

### Phosh Won't Start

```bash
# Check display manager
systemctl status gdm

# Check Phosh logs
journalctl --user -u phosh
```

### Controller Not Detected

```bash
# Check USB devices
lsusb | grep -i numark

# Check udev rules loaded
udevadm info /dev/snd/by-id/*

# Reload udev
sudo udevadm control --reload-rules
sudo udevadm trigger
```

---

## Part 16: Quick Reference

| Task | Command |
|------|---------|
| Check image | `sudo bootc status` |
| Update system | `sudo bootc upgrade` |
| Rollback | `sudo bootc rollback` |
| WiFi connect | `nmcli device wifi connect "SSID" password "pass"` |
| Install app | `flatpak install flathub <app.id>` |
| Run Mixxx | `flatpak run org.mixxx.Mixxx` |
| Run Spotify | `flatpak run com.spotify.Client` |
| Touch daemon | `systemctl status iptsd` |
| View logs | `journalctl -b` |
| Reboot | `sudo reboot` |

---

## Part 17: File Inventory

| File | Purpose |
|------|---------|
| `Containerfile` | Main image build definition |
| `.github/workflows/build.yml` | CI/CD automation |
| `config/flatpak-apps.txt` | Default Flatpak apps to install |
| `config/surface-udev.rules` | Surface hardware rules |
| `scripts/configure-phosh.sh` | Phosh customization |
| `scripts/setup-flatpak.sh` | First-boot Flatpak setup |

---

## Security Notes

- **Change default password immediately** after first boot
- **Signing keys**: `cosign.key` should only exist in GitHub Secrets
- **Flatpak permissions**: Review with `flatpak info --show-permissions <app>`
- **Updates**: Enable automatic bootc updates for security patches

---

## Known Limitations

1. **Type Cover hot-plug**: May require reconnection after sleep
2. **Secure Boot**: Requires manual key enrollment or disabled
3. **Netflix 4K**: Limited to 1080p on Linux (Widevine L3)
4. **Battery life**: ~6-8 hours typical (tune with powertop)

---

*Last updated: December 2024*
*Target: Surface Pro 7 with Fedora 42 bootc + Phosh*
