#!/bin/bash

# Ubuntu GUI Customization Script - Windows 11 Style
# Makes Ubuntu feel more familiar for Windows users

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
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

# Check if running on Ubuntu with GNOME
check_environment() {
    log "Checking environment compatibility..."
    
    if ! command -v gnome-shell &> /dev/null; then
        error "This script requires GNOME desktop environment"
        exit 1
    fi
    
    if [[ ! -f /etc/lsb-release ]] || ! grep -q "Ubuntu" /etc/lsb-release; then
        warning "This script is designed for Ubuntu but may work on other GNOME-based distributions"
    fi
    
    success "Environment check passed"
}

# Install required packages
install_dependencies() {
    log "Installing required packages..."
    
    sudo apt update
    
    # Essential packages for GUI customization
    local packages=(
        "gnome-tweaks"
        "gnome-shell-extensions"
        "chrome-gnome-shell"
        "gnome-shell-extension-manager"
        "dconf-editor"
        "nemo"
        "nemo-fileroller"
        "synaptic"
        "curl"
        "wget"
        "unzip"
        "git"
    )
    
    sudo apt install -y "${packages[@]}"
    success "Dependencies installed"
}

# Install GNOME extensions
install_extensions() {
    log "Installing GNOME extensions..."
    
    # Use our improved extension installer
    local installer_script="$(dirname "$0")/install_gnome_extensions.sh"
    if [[ -f "$installer_script" ]]; then
        log "Running improved extension installer..."
        bash "$installer_script"
    else
        # Fallback to package manager installation
        log "Fallback: Installing extensions via package manager..."
        
        sudo apt install -y gnome-shell-extension-manager
        
        # Try to install available packages
        local extensions=(
            "gnome-shell-extension-dash-to-panel"
            "gnome-shell-extension-desktop-icons-ng"
        )
        
        for ext in "${extensions[@]}"; do
            if apt-cache show "$ext" &> /dev/null; then
                sudo apt install -y "$ext"
                success "Installed $ext"
            else
                warning "$ext not available - manual installation required"
            fi
        done
        
        warning "Some extensions may need manual installation via Extension Manager"
        warning "Open 'Extensions' app after setup to install missing extensions"
    fi
    
    success "GNOME extensions installation completed"
}

# Install Windows 11-like themes
install_themes() {
    log "Installing Windows 11-like themes..."
    
    # Create themes directory
    mkdir -p ~/.themes ~/.icons
    
    # Install WhiteSur GTK theme
    log "Installing WhiteSur GTK theme..."
    cd /tmp
    git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git
    cd WhiteSur-gtk-theme
    ./install.sh -c Dark -c Light
    cd ..
    rm -rf WhiteSur-gtk-theme
    
    # Install Windows 11-style icons
    log "Installing Windows 11-style icon theme..."
    wget -O /tmp/fluent-icons.tar.xz "https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/heads/master.tar.gz"
    tar -xf /tmp/fluent-icons.tar.xz -C /tmp/
    cd /tmp/Fluent-icon-theme-master
    ./install.sh
    cd ..
    rm -rf Fluent-icon-theme-master fluent-icons.tar.xz
    
    success "Themes installed"
}

# Configure desktop for Windows 11-like experience
configure_desktop() {
    log "Configuring desktop for Windows 11-like experience..."
    
    # Set GTK theme
    gsettings set org.gnome.desktop.interface gtk-theme "WhiteSur-Dark"
    gsettings set org.gnome.desktop.interface icon-theme "Fluent"
    
    # Configure window controls (close, minimize, maximize on the right like Windows)
    gsettings set org.gnome.desktop.wm.preferences button-layout ":minimize,maximize,close"
    
    # Enable desktop icons
    gsettings set org.gnome.desktop.background show-desktop-icons true
    
    # Configure Dash to Panel for Windows-like taskbar
    dconf write /org/gnome/shell/extensions/dash-to-panel/panel-position "'BOTTOM'"
    dconf write /org/gnome/shell/extensions/dash-to-panel/panel-size "48"
    dconf write /org/gnome/shell/extensions/dash-to-panel/show-activities-button "false"
    dconf write /org/gnome/shell/extensions/dash-to-panel/show-appmenu "false"
    
    # Configure ArcMenu
    dconf write /org/gnome/shell/extensions/arcmenu/menu-layout "'Windows'"
    dconf write /org/gnome/shell/extensions/arcmenu/position-in-panel "'Left'"
    
    success "Desktop configured"
}

# Create desktop icons for common applications
create_desktop_icons() {
    log "Creating desktop icons..."
    
    # Ensure desktop directory exists
    mkdir -p ~/Desktop
    
    # Create desktop icons for common applications
    cat > ~/Desktop/Files.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Files
Comment=Access and organize files
Icon=org.gnome.Nautilus
Exec=nautilus
NoDisplay=false
Categories=GNOME;GTK;Utility;Core;FileManager;
StartupNotify=true
MimeType=inode/directory;
EOF

    cat > ~/Desktop/Terminal.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Terminal
Comment=Use the command line
Icon=org.gnome.Terminal
Exec=gnome-terminal
NoDisplay=false
Categories=GNOME;GTK;System;TerminalEmulator;
StartupNotify=true
EOF

    cat > ~/Desktop/Software.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Software
Comment=Add or remove software installed on the system
Icon=org.gnome.Software
Exec=gnome-software
NoDisplay=false
Categories=GNOME;GTK;System;PackageManager;
StartupNotify=true
EOF

    # Make desktop files executable
    chmod +x ~/Desktop/*.desktop
    
    # Trust desktop files (GNOME 3.38+)
    gio set ~/Desktop/Files.desktop metadata::trusted true
    gio set ~/Desktop/Terminal.desktop metadata::trusted true
    gio set ~/Desktop/Software.desktop metadata::trusted true
    
    success "Desktop icons created"
}

# Set up Windows-compatible keyboard shortcuts
setup_keyboard_shortcuts() {
    log "Setting up Windows-compatible keyboard shortcuts..."
    
    # Windows key + D to show desktop
    gsettings set org.gnome.desktop.wm.keybindings show-desktop "['<Super>d']"
    
    # Windows key + L to lock screen
    gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "['<Super>l']"
    
    # Windows key + R for run dialog (Alt+F2)
    gsettings set org.gnome.desktop.wm.keybindings panel-run-dialog "['<Super>r', '<Alt>F2']"
    
    # Windows key + X for power user menu (activities)
    gsettings set org.gnome.desktop.wm.keybindings panel-main-menu "['<Super>x']"
    
    success "Keyboard shortcuts configured"
}

# Install additional useful applications
install_applications() {
    log "Installing additional useful applications..."
    
    # Install applications that improve the Windows-like experience
    local apps=(
        "firefox"           # Web browser
        "thunderbird"       # Email client
        "libreoffice"      # Office suite
        "gimp"             # Image editor
        "vlc"              # Media player
        "code"             # VS Code (if available)
        "remmina"          # Remote desktop
        "timeshift"        # System backup
    )
    
    for app in "${apps[@]}"; do
        if apt-cache show "$app" &> /dev/null; then
            sudo apt install -y "$app"
            success "Installed $app"
        else
            warning "Package $app not found in repositories"
        fi
    done
}

# Set Nemo as default file manager
set_nemo_default() {
    log "Setting Nemo as default file manager..."
    
    # Set Nemo as default for file management
    xdg-mime default nemo.desktop inode/directory
    
    # Configure Nemo
    gsettings set org.nemo.desktop show-desktop-icons true
    gsettings set org.nemo.desktop desktop-layout 'true::false'
    
    success "Nemo configured as default file manager"
}

# Main execution function
main() {
    echo -e "${BLUE}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                Ubuntu GUI Customization Script              ║
║              Making Ubuntu Feel Like Windows 11             ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    local action=${1:-"all"}
    
    case $action in
        "all")
            check_environment
            install_dependencies
            install_extensions
            install_themes
            configure_desktop
            create_desktop_icons
            setup_keyboard_shortcuts
            install_applications
            set_nemo_default
            ;;
        "taskbar")
            install_dependencies
            install_extensions
            configure_desktop
            ;;
        "desktop")
            install_extensions
            create_desktop_icons
            ;;
        "theme")
            install_themes
            configure_desktop
            ;;
        "apps")
            install_applications
            ;;
        *)
            echo "Usage: $0 [all|taskbar|desktop|theme|apps]"
            echo "  all     - Complete Windows 11-like setup (default)"
            echo "  taskbar - Install Windows-like taskbar"
            echo "  desktop - Set up desktop icons"
            echo "  theme   - Install Windows 11-like themes"
            echo "  apps    - Install useful applications"
            exit 1
            ;;
    esac
    
    echo -e "${GREEN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                     Setup Complete! 🎉                      ║
║                                                              ║
║  Please log out and log back in to see all changes.         ║
║                                                              ║
║  To further customize:                                       ║
║  • Open GNOME Tweaks for advanced settings                  ║
║  • Use Extension Manager to configure extensions            ║
║  • Run dconf-editor for detailed customizations             ║
║                                                              ║
║  Enjoy your Windows 11-like Ubuntu experience!              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Run main function with all arguments
main "$@"
