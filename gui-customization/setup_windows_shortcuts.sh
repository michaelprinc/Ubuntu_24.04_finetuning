#!/bin/bash

# Windows-Compatible Keyboard Shortcuts Setup for Ubuntu

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log "Setting up Windows-compatible keyboard shortcuts..."

# Windows key + R for run dialog (like Windows Run)
gsettings set org.gnome.desktop.wm.keybindings panel-run-dialog "['<Super>r', '<Alt>F2']"

# Windows key + E for file manager (like Windows Explorer)
gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']"

# Windows key + I for settings (like Windows Settings)
gsettings set org.gnome.settings-daemon.plugins.media-keys control-center "['<Super>i']"

# Windows key + X for power user menu (map to activities)
gsettings set org.gnome.desktop.wm.keybindings panel-main-menu "['<Super>x']"

# Windows key + A for action center (map to show applications)
gsettings set org.gnome.shell.keybindings toggle-application-view "['<Super>a']"

# Windows key + S for search (map to overview)
gsettings set org.gnome.shell.keybindings toggle-overview "['<Super>s']"

# Ctrl + Shift + Esc for system monitor (like Task Manager)
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/taskmanager/ name 'System Monitor'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/taskmanager/ command 'gnome-system-monitor'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/taskmanager/ binding '<Control><Shift>Escape'

# Set up the custom keybinding
existing_keybindings=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
if [[ "$existing_keybindings" == "@as []" ]]; then
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/taskmanager/']"
else
    # Add to existing keybindings if not already present
    if [[ ! "$existing_keybindings" =~ "taskmanager" ]]; then
        new_keybindings=$(echo "$existing_keybindings" | sed "s/\]$/, '\/org\/gnome\/settings-daemon\/plugins\/media-keys\/custom-keybindings\/taskmanager\/'\]/")
        gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_keybindings"
    fi
fi

success "Windows-compatible keyboard shortcuts configured!"

echo ""
echo "Configured shortcuts:"
echo "  Super + R  →  Run dialog (like Windows Run)"
echo "  Super + E  →  File Manager (like Windows Explorer)"
echo "  Super + I  →  Settings (like Windows Settings)"
echo "  Super + X  →  Main menu (like Windows Power User menu)"
echo "  Super + A  →  Show applications (like Windows Action Center)"
echo "  Super + S  →  Overview (like Windows Search)"
echo "  Ctrl+Shift+Esc  →  System Monitor (like Windows Task Manager)"
echo ""
echo "Note: You may need to log out and back in for all shortcuts to work."
