#!/bin/bash

# Desktop Icon Creator for Ubuntu
# Creates desktop shortcuts for applications

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to create desktop icon for existing application
create_desktop_icon() {
    local app_name="$1"
    
    if [[ -z "$app_name" ]]; then
        error "Usage: $0 'Application Name'"
        error "Example: $0 'Firefox' or $0 'Visual Studio Code'"
        exit 1
    fi
    
    # Ensure desktop directory exists
    mkdir -p ~/Desktop
    
    # Search for the application in /usr/share/applications
    local desktop_file=""
    local search_patterns=(
        "${app_name,,}.desktop"
        "*${app_name,,}*.desktop"
        "${app_name,,}-***.desktop"
    )
    
    for pattern in "${search_patterns[@]}"; do
        desktop_file=$(find /usr/share/applications /var/lib/snapd/desktop/applications ~/.local/share/applications -name "$pattern" -type f 2>/dev/null | head -1)
        if [[ -n "$desktop_file" ]]; then
            break
        fi
    done
    
    if [[ -z "$desktop_file" ]]; then
        error "Could not find desktop file for '$app_name'"
        echo "Available applications:"
        ls /usr/share/applications/*.desktop 2>/dev/null | head -10 | xargs -I {} basename {} .desktop
        echo "... (and more)"
        exit 1
    fi
    
    # Get the desktop file name
    local desktop_filename=$(basename "$desktop_file")
    local target_path="~/Desktop/$desktop_filename"
    
    # Copy the desktop file to desktop
    cp "$desktop_file" ~/Desktop/
    
    # Make it executable
    chmod +x ~/Desktop/"$desktop_filename"
    
    # Trust the desktop file (GNOME 3.38+)
    gio set ~/Desktop/"$desktop_filename" metadata::trusted true 2>/dev/null || true
    
    success "Created desktop icon for '$app_name'"
    success "Desktop file: $desktop_filename"
}

# Function to create custom desktop icon
create_custom_icon() {
    local name="$1"
    local exec_path="$2"
    local icon_path="$3"
    local comment="${4:-$name}"
    
    if [[ -z "$name" || -z "$exec_path" ]]; then
        error "Usage: $0 custom 'Name' '/path/to/executable' ['/path/to/icon.png'] ['Comment']"
        exit 1
    fi
    
    # Use default icon if not provided
    if [[ -z "$icon_path" ]]; then
        icon_path="application-x-executable"
    fi
    
    # Create desktop file
    local desktop_filename="${name// /_}.desktop"
    
    cat > ~/Desktop/"$desktop_filename" << EOF
[Desktop Entry]
Type=Application
Name=$name
Comment=$comment
Icon=$icon_path
Exec=$exec_path
NoDisplay=false
Categories=Utility;
StartupNotify=true
EOF
    
    # Make it executable
    chmod +x ~/Desktop/"$desktop_filename"
    
    # Trust the desktop file
    gio set ~/Desktop/"$desktop_filename" metadata::trusted true 2>/dev/null || true
    
    success "Created custom desktop icon for '$name'"
}

# List available applications
list_applications() {
    echo "Available applications for desktop icons:"
    echo "=========================================="
    
    # Parse .desktop files and extract names
    for file in /usr/share/applications/*.desktop; do
        if [[ -f "$file" ]]; then
            local name=$(grep "^Name=" "$file" | head -1 | cut -d'=' -f2)
            local exec=$(grep "^Exec=" "$file" | head -1 | cut -d'=' -f2 | cut -d' ' -f1)
            if [[ -n "$name" && -n "$exec" ]]; then
                printf "%-30s (%s)\n" "$name" "$(basename "$file" .desktop)"
            fi
        fi
    done | sort | head -20
    
    echo "... (showing first 20, there are more)"
    echo ""
    echo "Usage examples:"
    echo "  $0 'Firefox'"
    echo "  $0 'Visual Studio Code'"
    echo "  $0 'LibreOffice Writer'"
}

# Create common desktop icons
create_common_icons() {
    echo "Creating common desktop icons..."
    
    local common_apps=(
        "Firefox"
        "Files"
        "Terminal"
        "Software"
        "Settings"
        "Text Editor"
        "Calculator"
    )
    
    for app in "${common_apps[@]}"; do
        create_desktop_icon "$app" 2>/dev/null || warning "Could not create icon for $app"
    done
    
    success "Created common desktop icons"
}

# Main function
main() {
    local action="$1"
    
    case "$action" in
        "custom")
            shift
            create_custom_icon "$@"
            ;;
        "list")
            list_applications
            ;;
        "common")
            create_common_icons
            ;;
        "")
            error "Usage: $0 'Application Name' | custom 'Name' 'Path' | list | common"
            echo ""
            echo "Examples:"
            echo "  $0 'Firefox'                                    # Create icon for Firefox"
            echo "  $0 custom 'My App' '/path/to/app'              # Create custom icon"
            echo "  $0 list                                         # List available apps"
            echo "  $0 common                                       # Create common icons"
            exit 1
            ;;
        *)
            create_desktop_icon "$action"
            ;;
    esac
}

main "$@"
