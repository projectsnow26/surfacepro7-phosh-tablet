#!/usr/bin/env bash
# Phosh-specific configuration script for Surface devices
set -euo pipefail

echo "=== Configuring Phosh for Surface devices ==="

# Ensure GDM uses Wayland (Phosh requires Wayland)
mkdir -p /etc/gdm
cat > /etc/gdm/custom.conf << 'EOF'
[daemon]
WaylandEnable=true
DefaultSession=phosh.desktop
AutomaticLoginEnable=false

[security]

[xdmcp]

[chooser]

[debug]
EOF

echo "=== Configuring Phosh session ==="

# Ensure Phosh session file is properly registered
# The phosh package should install this, but we verify it exists
if [ ! -f /usr/share/wayland-sessions/phosh.desktop ]; then
    echo "WARNING: phosh.desktop session file not found, creating..."
    mkdir -p /usr/share/wayland-sessions
    cat > /usr/share/wayland-sessions/phosh.desktop << 'EOF'
[Desktop Entry]
Name=Phosh
Comment=Phosh Mobile Shell
Exec=/usr/libexec/phosh
TryExec=/usr/libexec/phosh
Type=Application
DesktopNames=Phosh;GNOME;
EOF
fi

echo "=== Configuring phoc for Surface display ==="

# Create default phoc.ini configuration optimized for Surface tablets
mkdir -p /etc/phosh
cat > /etc/phosh/phoc.ini << 'EOF'
# Phoc configuration for Surface devices
# Surface Pro tablets typically have high-DPI displays

[core]
# Enable XWayland for X11 app compatibility
xwayland=true

[output:eDP-1]
# Surface display - adjust scale based on your device
# Surface Pro 7/8/9 typically work well with scale 2.0
# Adjust if text is too small or too large
scale = 2.0

[output:DSI-1]
# Alternative output name on some devices
scale = 2.0
EOF

echo "=== Setting up Surface-specific udev rules ==="

# Create udev rules for Surface hardware
mkdir -p /etc/udev/rules.d
cat > /etc/udev/rules.d/99-surface.rules << 'EOF'
# Surface tablet mode detection
ACTION=="change", SUBSYSTEM=="input", ATTR{name}=="*Type Cover*", ENV{ID_INPUT_KEYBOARD}="1"

# Surface Pen
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="045e", MODE="0666"
EOF

echo "=== Configuring power management for tablets ==="

# Create power-saving profile configuration
mkdir -p /etc/power-profiles-daemon.d
cat > /etc/power-profiles-daemon.d/surface.conf << 'EOF'
# Surface power profile configuration
# Optimize for battery life on mobile devices
EOF

echo "=== Setting up Flatpak for user ==="

# Ensure Flathub is available system-wide (will be configured by default-flatpaks module)
# This is a backup in case the module doesn't run
if command -v flatpak &> /dev/null; then
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
fi

echo "=== Configuring touch gestures ==="

# libinput configuration for touch
mkdir -p /etc/libinput
cat > /etc/libinput/local-overrides.quirks << 'EOF'
# Surface touch screen quirks
[Microsoft Surface Touch]
MatchVendor=0x045E
MatchUdevType=touchscreen
AttrPalmSizeThreshold=10
EOF

echo "=== Setting locale defaults ==="

# Ensure en_US.UTF-8 is the default locale
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "=== Phosh configuration complete ==="
