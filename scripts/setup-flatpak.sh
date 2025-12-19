#!/bin/bash
# First-boot Flatpak application installer
# Runs once after first boot to install streaming and DJ apps

set -euo pipefail

FLATPAK_APPS_FILE="/usr/share/fedora-phosh-surface/flatpak-apps.txt"
LOG_FILE="/var/log/flatpak-setup.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "Starting Flatpak application setup..."

# Wait for network
log "Waiting for network connectivity..."
for i in {1..60}; do
    if ping -c 1 flathub.org &>/dev/null; then
        log "Network is available"
        break
    fi
    sleep 2
done

# Ensure Flathub is added
log "Ensuring Flathub repository is configured..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Install apps from list
if [[ -f "$FLATPAK_APPS_FILE" ]]; then
    log "Reading apps from $FLATPAK_APPS_FILE"
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Trim whitespace
        app_id=$(echo "$line" | xargs)
        
        log "Installing: $app_id"
        if flatpak install -y --noninteractive flathub "$app_id" 2>&1 | tee -a "$LOG_FILE"; then
            log "Successfully installed: $app_id"
        else
            log "WARNING: Failed to install: $app_id"
        fi
    done < "$FLATPAK_APPS_FILE"
else
    log "WARNING: Flatpak apps list not found at $FLATPAK_APPS_FILE"
fi

# Grant necessary permissions for Mixxx (DJ controller access)
log "Configuring Flatpak permissions for Mixxx..."
if flatpak info org.mixxx.Mixxx &>/dev/null; then
    # Mixxx needs access to all devices for DJ controllers
    flatpak override --user org.mixxx.Mixxx --device=all 2>/dev/null || true
    flatpak override --user org.mixxx.Mixxx --filesystem=/run/media 2>/dev/null || true
    flatpak override --user org.mixxx.Mixxx --filesystem=xdg-music 2>/dev/null || true
    log "Mixxx permissions configured"
fi

# Grant permissions for Spotify
log "Configuring Flatpak permissions for Spotify..."
if flatpak info com.spotify.Client &>/dev/null; then
    flatpak override --user com.spotify.Client --filesystem=xdg-music:ro 2>/dev/null || true
    log "Spotify permissions configured"
fi

# Update all installed Flatpaks
log "Updating all Flatpak applications..."
flatpak update -y --noninteractive 2>&1 | tee -a "$LOG_FILE" || true

log "Flatpak setup complete!"
log "Installed applications:"
flatpak list --app --columns=name,application | tee -a "$LOG_FILE"

exit 0
