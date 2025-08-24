#!/bin/bash

# GNOME Extensions Installer for Ubuntu 24.04 (GNOME 46)
# Improved version with multiple installation methods

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check GNOME version
check_gnome_version() {
    log "Checking GNOME Shell version..."
    local gnome_version=$(gnome-shell --version | grep -oP '\d+\.\d+' | head -1)
    echo "GNOME Shell version: $gnome_version"
    
    if [[ "$gnome_version" == "46."* ]]; then
        success "GNOME 46 detected - compatible"
        return 0
    else
        warning "GNOME version $gnome_version detected - extensions may not be compatible"
        return 1
    fi
}

# Method 1: Install via package manager (most reliable)
install_via_packages() {
    log "Installing extensions via package manager..."
    
    sudo apt update
    
    # Install Extension Manager
    sudo apt install -y gnome-shell-extension-manager
    
    # Check for available extension packages
    local extensions=(
        "gnome-shell-extension-dash-to-panel"
        "gnome-shell-extension-desktop-icons-ng" 
        "gnome-shell-extension-arc-menu"
    )
    
    for ext in "${extensions[@]}"; do
        if apt-cache show "$ext" &> /dev/null; then
            sudo apt install -y "$ext"
            success "Installed $ext"
        else
            warning "$ext not available in repositories"
        fi
    done
}

# Method 2: Install via Extension Manager (GUI method)
install_via_extension_manager() {
    log "Setting up Extension Manager for GUI installation..."
    
    # Install Extension Manager if not already installed
    if ! command -v extension-manager &> /dev/null; then
        if command -v flatpak &> /dev/null; then
            flatpak install -y flathub com.mattjakeman.ExtensionManager
            success "Extension Manager installed via Flatpak"
        else
            sudo apt install -y gnome-shell-extension-manager
            success "Extension Manager installed via apt"
        fi
    fi
    
    echo ""
    echo "🔧 Extension Manager installed!"
    echo "To install extensions manually:"
    echo "1. Open Extension Manager (search for 'Extensions' in Activities)"
    echo "2. Click 'Browse' tab"
    echo "3. Search for and install:"
    echo "   - Dash to Panel (ID: 1160)"
    echo "   - ArcMenu (ID: 3628)" 
    echo "   - Desktop Icons NG (ID: 2087)"
    echo ""
}

# Method 3: Manual installation from Git repositories
install_from_git() {
    log "Installing extensions from Git repositories..."
    
    mkdir -p ~/.local/share/gnome-shell/extensions
    cd /tmp
    
    # Dash to Panel
    log "Installing Dash to Panel from GitHub..."
    if git clone https://github.com/home-sweet-gnome/dash-to-panel.git; then
        cd dash-to-panel
        # Copy to extensions directory
        cp -r . ~/.local/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/
        cd ..
        rm -rf dash-to-panel
        success "Dash to Panel installed from Git"
    else
        warning "Could not clone Dash to Panel repository"
    fi
    
    # ArcMenu
    log "Installing ArcMenu from GitLab..."
    if git clone https://gitlab.com/arcmenu/ArcMenu.git; then
        cd ArcMenu
        cp -r . ~/.local/share/gnome-shell/extensions/arcmenu@arcmenu.com/
        cd ..
        rm -rf ArcMenu
        success "ArcMenu installed from Git"
    else
        warning "Could not clone ArcMenu repository"
    fi
    
    # Desktop Icons NG
    log "Installing Desktop Icons NG from GitLab..."
    if git clone https://gitlab.com/rastersoft/desktop-icons-ng.git; then
        cd desktop-icons-ng
        cp -r . ~/.local/share/gnome-shell/extensions/ding@rastersoft.com/
        cd ..
        rm -rf desktop-icons-ng
        success "Desktop Icons NG installed from Git"
    else
        warning "Could not clone Desktop Icons NG repository"
    fi
}

# Method 4: Install essential extensions manually
install_manually() {
    log "Attempting manual installation with updated URLs..."
    
    mkdir -p ~/.local/share/gnome-shell/extensions
    
    # Extension download function
    download_extension() {
        local name="$1"
        local url="$2"
        local dir="$3"
        
        log "Downloading $name..."
        if curl -L -f "$url" -o "/tmp/${name}.zip"; then
            mkdir -p "$dir"
            unzip -o "/tmp/${name}.zip" -d "$dir"
            success "$name downloaded and extracted"
            return 0
        else
            warning "Failed to download $name"
            return 1
        fi
    }
    
    # Try direct extension downloads (these URLs might work)
    download_extension "dash-to-panel" \
        "https://github.com/home-sweet-gnome/dash-to-panel/archive/refs/heads/master.zip" \
        "~/.local/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/"
        
    download_extension "arcmenu" \
        "https://gitlab.com/arcmenu/ArcMenu/-/archive/master/ArcMenu-master.zip" \
        "~/.local/share/gnome-shell/extensions/arcmenu@arcmenu.com/"
        
    download_extension "desktop-icons-ng" \
        "https://gitlab.com/rastersoft/desktop-icons-ng/-/archive/master/desktop-icons-ng-master.zip" \
        "~/.local/share/gnome-shell/extensions/ding@rastersoft.com/"
}

# Enable extensions
enable_extensions() {
    log "Enabling GNOME extensions..."
    
    local extensions=(
        "dash-to-panel@jderose9.github.com"
        "arcmenu@arcmenu.com"
        "ding@rastersoft.com"
    )
    
    for ext in "${extensions[@]}"; do
        if gnome-extensions list | grep -q "$ext"; then
            gnome-extensions enable "$ext" 2>/dev/null && success "Enabled $ext" || warning "Could not enable $ext"
        else
            warning "$ext not found - may need manual installation"
        fi
    done
}

# Show manual installation instructions
show_manual_instructions() {
    echo ""
    echo "📋 Manual Installation Instructions:"
    echo "=================================="
    echo ""
    echo "If automatic installation failed, install extensions manually:"
    echo ""
    echo "1. Open Firefox and go to: https://extensions.gnome.org"
    echo "2. Install the browser extension when prompted"
    echo "3. Search for and install these extensions:"
    echo "   • Dash to Panel (by charlesg99)"
    echo "   • ArcMenu (by andrew_z)"  
    echo "   • Desktop Icons NG (by rastersoft)"
    echo ""
    echo "4. Or use Extension Manager:"
    echo "   • Open 'Extensions' app"
    echo "   • Click 'Browse' tab"
    echo "   • Search and install the extensions"
    echo ""
    echo "5. After installation, log out and back in"
    echo ""
}

# Main installation function
main() {
    echo ""
    echo "🔧 GNOME Extensions Installer for Ubuntu 24.04"
    echo "=============================================="
    echo ""
    
    check_gnome_version
    
    log "Attempting multiple installation methods..."
    
    # Try different installation methods
    install_via_packages
    install_via_extension_manager
    
    # If package installation didn't work, try Git
    if ! gnome-extensions list | grep -q "dash-to-panel\|arcmenu\|ding"; then
        warning "Package installation incomplete, trying Git repositories..."
        install_from_git
    fi
    
    # If Git didn't work, try manual download
    if ! gnome-extensions list | grep -q "dash-to-panel\|arcmenu\|ding"; then
        warning "Git installation incomplete, trying manual download..."
        install_manually
    fi
    
    # Enable installed extensions
    enable_extensions
    
    # Show results
    echo ""
    echo "📊 Installation Results:"
    echo "======================="
    gnome-extensions list | grep -E "(dash-to-panel|arcmenu|ding)" || echo "No target extensions found"
    
    # Show manual instructions if needed
    if ! gnome-extensions list | grep -q "dash-to-panel\|arcmenu\|ding"; then
        warning "Automatic installation may have failed"
        show_manual_instructions
    else
        echo ""
        echo "🎉 Extensions installed successfully!"
        echo "Please log out and back in to activate the extensions."
        echo ""
        echo "After login, configure the extensions:"
        echo "• Open 'Extensions' app to configure settings"
        echo "• Or run: gnome-extensions prefs <extension-id>"
    fi
}

main "$@"
