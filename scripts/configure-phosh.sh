#!/bin/bash
# Configure Phosh settings for Surface Pro 7
# This script is run during image build

set -euo pipefail

echo "Configuring Phosh for Surface Pro 7..."

# =============================================================================
# GDM configuration for Phosh
# =============================================================================

# Configure GDM to use Phosh session by default
mkdir -p /etc/gdm
cat > /etc/gdm/custom.conf << 'EOF'
[daemon]
# Uncomment to auto-login (useful for kiosk mode)
# AutomaticLoginEnable=True
# AutomaticLogin=dj

# Use Wayland
WaylandEnable=true

[security]

[xdmcp]

[chooser]

[debug]
EOF

# =============================================================================
# Phosh mobile settings
# =============================================================================

# Create Phosh config directory
mkdir -p /etc/phosh

# Configure Phosh for tablet form factor
cat > /etc/phosh/phoc.ini << 'EOF'
# Phoc (Phosh compositor) configuration
# Optimized for Surface Pro 7 (12.3" 2736x1824 display)

[core]
# Use the preferred GNOME shell mode
xwayland = true

[output:eDP-1]
# Surface Pro 7 display
# Scale 2.0 gives ~150 effective DPI (comfortable for touch)
scale = 2.0

# Rotation: normal, 90, 180, 270
transform = normal

[output:*]
# Default for external displays
scale = 1.0
EOF

# =============================================================================
# Squeekboard (on-screen keyboard) configuration
# =============================================================================

mkdir -p /etc/squeekboard
cat > /etc/squeekboard/squeekboard.yaml << 'EOF'
# Squeekboard configuration
# On-screen keyboard settings for Phosh

# Terminal layout includes more keys
layouts:
  - us
  - terminal

# Appearance
theme:
  name: default

# Behavior
hints:
  word_hints: true
  emoji_hints: true
EOF

# =============================================================================
# Touch gestures and input
# =============================================================================

# Configure libinput for touch
mkdir -p /etc/libinput
cat > /etc/libinput/local-overrides.quirks << 'EOF'
# Surface Pro 7 touchscreen and touchpad quirks

[Microsoft Surface Pro 7 Touchscreen]
MatchVendor=0x045E
MatchProduct=0x099A
AttrPalmSizeThreshold=200

[Microsoft Surface Type Cover]
MatchVendor=0x045E
MatchProduct=0x09AF
AttrThumbSizeThreshold=200
AttrPalmSizeThreshold=180
EOF

echo "Phosh configuration complete!"
