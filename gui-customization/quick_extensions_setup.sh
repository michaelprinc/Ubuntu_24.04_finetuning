#!/bin/bash

# Quick GNOME Extensions Status Checker and Installer
# Optimized for Ubuntu 24.04 with existing Desktop Icons NG

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

# Check current extension status
check_extensions_status() {
    log "Checking current GNOME extensions..."
    echo ""
    
    local required_extensions=(
        "ding@rastersoft.com:Desktop Icons NG"
        "dash-to-panel@jderose9.github.com:Dash to Panel"
        "arcmenu@arcmenu.com:ArcMenu"
    )
    
    local installed_count=0
    local total_count=${#required_extensions[@]}
    
    for ext_info in "${required_extensions[@]}"; do
        local ext_id="${ext_info%%:*}"
        local ext_name="${ext_info##*:}"
        
        if gnome-extensions list | grep -q "$ext_id"; then
            local state=$(gnome-extensions info "$ext_id" | grep "State:" | awk '{print $2}')
            success "$ext_name is installed and $state"
            ((installed_count++))
        else
            warning "$ext_name is NOT installed"
        fi
    done
    
    echo ""
    echo "📊 Status: $installed_count/$total_count required extensions installed"
    echo ""
    
    return $((total_count - installed_count))
}

# Install missing extensions via Extension Manager
install_missing_extensions() {
    log "Installing Extension Manager for manual installation..."
    
    # Ensure Extension Manager is installed
    if ! command -v extension-manager &> /dev/null; then
        sudo apt install -y gnome-shell-extension-manager
        success "Extension Manager installed"
    else
        success "Extension Manager already installed"
    fi
    
    echo ""
    echo "🔧 Manual Installation Required"
    echo "==============================="
    echo ""
    echo "Please install the missing extensions manually:"
    echo ""
    echo "1. Open 'Extensions' app (search for it in Activities)"
    echo "2. Click the 'Browse' tab"
    echo "3. Search for and install these extensions:"
    echo ""
    
    # Check which ones are missing
    if ! gnome-extensions list | grep -q "dash-to-panel@jderose9.github.com"; then
        echo "   🔍 Search: 'Dash to Panel'"
        echo "      📁 ID: 1160"
        echo "      👤 Author: charlesg99"
        echo "      📝 Description: Windows-like taskbar"
        echo ""
    fi
    
    if ! gnome-extensions list | grep -q "arcmenu@arcmenu.com"; then
        echo "   🔍 Search: 'ArcMenu'"
        echo "      📁 ID: 3628"
        echo "      👤 Author: andrew_z"
        echo "      📝 Description: Start menu replacement"
        echo ""
    fi
    
    echo "4. After installation, log out and back in"
    echo "5. Run this script again to verify installation"
    echo ""
    
    # Open Extension Manager
    if command -v extension-manager &> /dev/null; then
        echo "🚀 Opening Extension Manager for you..."
        extension-manager &
        sleep 2
    fi
}

# Configure installed extensions
configure_extensions() {
    log "Configuring installed extensions..."
    
    # Enable Desktop Icons NG if not enabled
    if gnome-extensions list | grep -q "ding@rastersoft.com"; then
        gnome-extensions enable ding@rastersoft.com 2>/dev/null || true
        success "Desktop Icons NG enabled"
    fi
    
    # Configure Dash to Panel if installed
    if gnome-extensions list | grep -q "dash-to-panel@jderose9.github.com"; then
        gnome-extensions enable dash-to-panel@jderose9.github.com 2>/dev/null || true
        success "Dash to Panel enabled"
        
        # Apply Windows-like configuration
        log "Applying Windows-like configuration to Dash to Panel..."
        dconf write /org/gnome/shell/extensions/dash-to-panel/panel-position "'BOTTOM'" 2>/dev/null || true
        dconf write /org/gnome/shell/extensions/dash-to-panel/panel-size "48" 2>/dev/null || true
        dconf write /org/gnome/shell/extensions/dash-to-panel/show-activities-button "false" 2>/dev/null || true
        dconf write /org/gnome/shell/extensions/dash-to-panel/show-appmenu "false" 2>/dev/null || true
    fi
    
    # Configure ArcMenu if installed
    if gnome-extensions list | grep -q "arcmenu@arcmenu.com"; then
        gnome-extensions enable arcmenu@arcmenu.com 2>/dev/null || true
        success "ArcMenu enabled"
        
        # Apply Windows-like configuration
        log "Applying Windows-like configuration to ArcMenu..."
        dconf write /org/gnome/shell/extensions/arcmenu/menu-layout "'Windows'" 2>/dev/null || true
        dconf write /org/gnome/shell/extensions/arcmenu/position-in-panel "'Left'" 2>/dev/null || true
    fi
}

# Show web browser installation option
show_browser_option() {
    echo ""
    echo "🌐 Alternative: Browser Installation"
    echo "==================================="
    echo ""
    echo "You can also install extensions via web browser:"
    echo ""
    echo "1. Open Firefox or Chrome"
    echo "2. Go to: https://extensions.gnome.org"
    echo "3. Install the browser extension when prompted"
    echo "4. Search for and install:"
    echo "   • Dash to Panel: https://extensions.gnome.org/extension/1160/"
    echo "   • ArcMenu: https://extensions.gnome.org/extension/3628/"
    echo ""
}

# Main function
main() {
    echo ""
    echo "🔧 GNOME Extensions Quick Setup for Ubuntu 24.04"
    echo "================================================"
    echo ""
    
    # Check current status
    if check_extensions_status; then
        success "All required extensions are already installed!"
        configure_extensions
        echo ""
        echo "🎉 Setup complete! Your Ubuntu desktop now has:"
        echo "   • Desktop icons support (Desktop Icons NG)"
        echo "   • Windows-like taskbar (Dash to Panel)"
        echo "   • Start menu (ArcMenu)"
        echo ""
        echo "💡 Tip: If you don't see the changes, log out and back in."
    else
        warning "Some extensions are missing."
        install_missing_extensions
        show_browser_option
        configure_extensions
    fi
    
    echo ""
    echo "📋 Current Extensions Status:"
    echo "=============================="
    gnome-extensions list | while read ext; do
        if [[ -n "$ext" ]]; then
            local state=$(gnome-extensions info "$ext" 2>/dev/null | grep "State:" | awk '{print $2}' || echo "UNKNOWN")
            local name=$(gnome-extensions info "$ext" 2>/dev/null | grep "Name:" | cut -d' ' -f3- || echo "$ext")
            echo "• $name: $state"
        fi
    done
    echo ""
}

main "$@"
