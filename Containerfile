# Fedora Phosh Surface Pro 7 - Bootable Container Image
# 
# This Containerfile builds an immutable Fedora desktop with:
# - Phosh mobile shell (touch-optimized)
# - linux-surface kernel (Surface Pro 7 hardware support)
# - Flatpak support for apps (Mixxx, Spotify, streaming)
# - PipeWire audio stack
#
# Base: Fedora 42 bootc
# Target: Microsoft Surface Pro 7

FROM quay.io/fedora/fedora-bootc:42

# Build arguments for versioning
ARG IMAGE_VERSION="1.0.0"
ARG BUILD_DATE

# Labels for image identification
LABEL org.opencontainers.image.title="Fedora Phosh Surface"
LABEL org.opencontainers.image.description="Immutable Fedora with Phosh for Surface Pro 7 - Media & DJ workstation"
LABEL org.opencontainers.image.version="${IMAGE_VERSION}"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL containers.bootc="1"

# =============================================================================
# STAGE 1: Add repositories
# =============================================================================

RUN <<EOF
set -xeuo pipefail

# Import linux-surface GPG key
curl -sSL https://raw.githubusercontent.com/linux-surface/linux-surface/master/pkg/keys/surface.asc \
  | gpg --dearmor > /etc/pki/rpm-gpg/RPM-GPG-KEY-linux-surface

# Add linux-surface repo
cat > /etc/yum.repos.d/linux-surface.repo << 'REPO'
[linux-surface]
name=Linux Surface Kernel
baseurl=https://pkg.surfacelinux.com/fedora/f$releasever
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-linux-surface
REPO

# Add RPMFusion Free and Nonfree (for full multimedia codecs)
dnf install -y \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-42.noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-42.noarch.rpm

EOF

# =============================================================================
# STAGE 2: Install linux-surface kernel
# =============================================================================

RUN <<EOF
set -xeuo pipefail

# Install Surface kernel and hardware support
dnf install -y --allowerasing \
  kernel-surface \
  kernel-surface-devel \
  iptsd \
  libwacom-surface

# Note: iptsd uses a template unit (iptsd@.service) that is automatically
# started by udev when the touchscreen hardware is detected.

EOF

# =============================================================================
# STAGE 3: Install Phosh desktop environment
# =============================================================================

RUN <<EOF
set -xeuo pipefail

# Install Phosh and related packages
dnf install -y --allowerasing \
  phosh \
  phoc \
  squeekboard \
  gnome-control-center \
  gnome-contacts \
  gnome-calculator \
  gnome-calendar \
  gnome-clocks \
  gnome-weather \
  gnome-text-editor \
  gnome-console \
  gnome-software \
  nautilus \
  evince \
  eog \
  gnome-disk-utility \
  gnome-system-monitor \
  feedbackd \
  phosh-mobile-settings \
  xdg-desktop-portal-gnome \
  xdg-desktop-portal-gtk

# Install GDM for login
dnf install -y gdm

# Enable GDM
systemctl enable gdm

# Set graphical target
systemctl set-default graphical.target

EOF

# =============================================================================
# STAGE 4: Install audio stack (PipeWire)
# =============================================================================

RUN <<EOF
set -xeuo pipefail

dnf install -y --allowerasing \
  pipewire \
  pipewire-pulseaudio \
  pipewire-alsa \
  pipewire-jack-audio-connection-kit \
  wireplumber \
  pavucontrol \
  alsa-utils \
  alsa-firmware

# Enable PipeWire for all users
mkdir -p /etc/systemd/user/default.target.wants
ln -sf /usr/lib/systemd/user/pipewire.service /etc/systemd/user/default.target.wants/
ln -sf /usr/lib/systemd/user/pipewire-pulse.service /etc/systemd/user/default.target.wants/
ln -sf /usr/lib/systemd/user/wireplumber.service /etc/systemd/user/default.target.wants/

EOF

# =============================================================================
# STAGE 5: Install Flatpak support
# =============================================================================

RUN <<EOF
set -xeuo pipefail

dnf install -y --allowerasing \
  flatpak \
  xdg-user-dirs \
  xdg-utils

# Add Flathub repository system-wide
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

EOF

# =============================================================================
# STAGE 6: Install networking and system tools
# =============================================================================

RUN <<EOF
set -xeuo pipefail

# Install additional tools (many networking packages already in base image)
# Note: tuned-ppd is the default in F42, not power-profiles-daemon
dnf install -y --allowerasing \
  NetworkManager-bluetooth \
  iwd \
  usbutils \
  pciutils \
  lshw \
  htop \
  wget \
  git \
  rsync \
  unzip

# Enable bluetooth service
systemctl enable bluetooth

EOF

# =============================================================================
# STAGE 7: Install browsers and multimedia
# =============================================================================

RUN <<EOF
set -xeuo pipefail

# Install Firefox and full ffmpeg from RPMFusion (not ffmpeg-free)
# Base image has ffmpeg-libs from RPMFusion, so use full ffmpeg
dnf install -y --allowerasing \
  firefox \
  ffmpeg \
  gstreamer1-plugin-openh264 \
  mozilla-openh264

EOF

# =============================================================================
# STAGE 8: Install multimedia codecs (RPMFusion)
# =============================================================================

RUN <<EOF
set -xeuo pipefail

dnf install -y --allowerasing \
  gstreamer1-plugins-ugly \
  gstreamer1-libav \
  intel-media-driver \
  libva-intel-driver \
  libva-utils \
  mesa-va-drivers \
  mesa-vdpau-drivers

EOF

# =============================================================================
# STAGE 9: Surface-specific configuration
# =============================================================================

# Copy Surface udev rules
COPY config/surface-udev.rules /etc/udev/rules.d/99-surface.rules

# Configure touch and pen settings
RUN <<EOF
set -xeuo pipefail

# Create iptsd config directory
mkdir -p /etc/iptsd

# Create basic iptsd config for Surface Pro 7
cat > /etc/iptsd/iptsd.conf << 'CONF'
[Device]
# Surface Pro 7 uses IPTS
# Default settings work well for most use cases

[Touch]
# Enable palm rejection
DisableOnPalm = true
DisableOnStylus = true

[Stylus]
# Enable stylus support
Enable = true
CONF

EOF

# =============================================================================
# STAGE 10: Phosh configuration
# =============================================================================

# Copy Phosh configuration
COPY config/phosh-favorites.txt /usr/share/phosh/favorites.txt
COPY scripts/configure-phosh.sh /usr/libexec/configure-phosh.sh

RUN <<EOF
set -xeuo pipefail

chmod +x /usr/libexec/configure-phosh.sh

# Create default Phosh settings
mkdir -p /etc/dconf/db/local.d
cat > /etc/dconf/db/local.d/00-phosh << 'DCONF'
[org/gnome/desktop/interface]
gtk-theme='Adwaita'
icon-theme='Adwaita'
cursor-theme='Adwaita'
font-name='Cantarell 11'
document-font-name='Cantarell 11'
monospace-font-name='Source Code Pro 10'
enable-animations=true
clock-show-seconds=false
clock-show-weekday=true

[org/gnome/desktop/peripherals/touchpad]
tap-to-click=true
natural-scroll=true

[org/gnome/desktop/input-sources]
sources=[('xkb', 'us')]

[org/gnome/desktop/session]
idle-delay=uint32 300

[org/gnome/desktop/screensaver]
lock-enabled=true
lock-delay=uint32 0

[org/gnome/shell]
favorite-apps=['org.gnome.Nautilus.desktop', 'firefox.desktop', 'org.gnome.Console.desktop', 'gnome-control-center.desktop']
DCONF

# Update dconf database
dconf update || true

EOF

# =============================================================================
# STAGE 11: First-boot setup script
# =============================================================================

COPY scripts/setup-flatpak.sh /usr/libexec/setup-flatpak.sh
COPY config/flatpak-apps.txt /usr/share/fedora-phosh-surface/flatpak-apps.txt

RUN <<EOF
set -xeuo pipefail

chmod +x /usr/libexec/setup-flatpak.sh

# Create first-boot service for Flatpak apps
cat > /etc/systemd/system/setup-flatpak-apps.service << 'SERVICE'
[Unit]
Description=Setup Flatpak Applications
After=network-online.target
Wants=network-online.target
ConditionPathExists=!/var/lib/.flatpak-apps-installed

[Service]
Type=oneshot
ExecStart=/usr/libexec/setup-flatpak.sh
ExecStartPost=/usr/bin/touch /var/lib/.flatpak-apps-installed
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE

systemctl enable setup-flatpak-apps.service

EOF

# =============================================================================
# STAGE 12: DJ/Audio configuration (for Mixxx)
# =============================================================================

RUN <<EOF
set -xeuo pipefail

# Add udev rules for DJ controllers
cat > /etc/udev/rules.d/99-dj-controllers.rules << 'UDEV'
# Numark Mixtrack Platinum FX
SUBSYSTEM=="usb", ATTR{idVendor}=="15e4", ATTR{idProduct}=="0141", MODE="0666", GROUP="audio"

# Generic DJ controller permissions
SUBSYSTEM=="usb", ATTR{idVendor}=="15e4", MODE="0666", GROUP="audio"
SUBSYSTEM=="usb", ATTR{idVendor}=="06f8", MODE="0666", GROUP="audio"
SUBSYSTEM=="usb", ATTR{idVendor}=="17cc", MODE="0666", GROUP="audio"
SUBSYSTEM=="usb", ATTR{idVendor}=="0582", MODE="0666", GROUP="audio"

# MIDI devices
KERNEL=="midi*", MODE="0666", GROUP="audio"
KERNEL=="snd/seq", MODE="0666", GROUP="audio"
KERNEL=="snd/timer", MODE="0666", GROUP="audio"
UDEV

# Configure realtime audio permissions
cat > /etc/security/limits.d/99-realtime-audio.conf << 'LIMITS'
@audio   -  rtprio     95
@audio   -  memlock    unlimited
@audio   -  nice       -19
LIMITS

EOF

# =============================================================================
# STAGE 13: Cleanup
# =============================================================================

RUN <<EOF
set -xeuo pipefail

# Clean package cache
dnf clean all

# Remove unnecessary files
rm -rf /var/cache/dnf/*
rm -rf /var/log/*
rm -rf /tmp/*

# Run bootc lint
bootc container lint

EOF

# =============================================================================
# Container metadata
# =============================================================================

ENV container=oci
STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]