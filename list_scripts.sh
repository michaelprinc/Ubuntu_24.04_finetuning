#!/bin/bash

# Ubuntu 24.04 Fine-Tuning - Script Overview
# Shows all available scripts organized by theme

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "═══════════════════════════════════════════════════════════════"
echo "🛠️  Ubuntu 24.04 Fine-Tuning - Available Scripts"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Function to list scripts in a directory
list_scripts() {
    local dir="$1"
    local title="$2"
    
    if [[ -d "$SCRIPT_DIR/$dir" ]]; then
        echo "📁 $title"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        # List shell scripts
        find "$SCRIPT_DIR/$dir" -name "*.sh" -type f | sort | while read -r script; do
            script_name=$(basename "$script")
            # Get first comment line as description
            description=$(head -5 "$script" | grep -E "^#.*[a-zA-Z]" | head -1 | sed 's/^# *//' || echo "")
            printf "  🔹 %-30s %s\n" "$script_name" "$description"
        done
        
        echo ""
    fi
}

# Function to show usage examples
show_usage() {
    echo "🚀 Quick Start Examples:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "# Run complete setup"
    echo "./setup_thematic.sh all"
    echo ""
    echo "# Run individual modules"
    echo "./setup_thematic.sh networking"
    echo "./setup_thematic.sh authentication"
    echo "./setup_thematic.sh gpu"
    echo ""
    echo "# Run specific utilities"
    echo "./authentication/howdy_manage.sh status"
    echo "./gpu/gpu_monitor.sh"
    echo "./docker/docker_manage.sh status"
    echo "./backup/system_backup.sh full"
    echo ""
    echo "# GUI customization"
    echo "./gui-customization/setup_windows_like_gui.sh"
    echo ""
}

# List all thematic directories
list_scripts "networking" "🌐 Networking & Drivers"
list_scripts "security" "🔒 Security Hardening"
list_scripts "authentication" "🔐 Biometric Authentication"
list_scripts "gpu" "🎮 GPU & Compute Stack"
list_scripts "virtualization" "🖥️ Virtualization & VM Management"
list_scripts "docker" "🐳 Docker & Containers"
list_scripts "performance" "⚡ Performance Tuning"
list_scripts "development" "🧑‍💻 Developer Tools"
list_scripts "backup" "💾 Backup & Recovery"
list_scripts "gui-customization" "🎨 GUI Customization"
list_scripts "GRUB" "🥾 GRUB Boot Configuration"

show_usage

echo "📖 Documentation:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Each folder contains a README.md with detailed usage instructions."
echo ""
echo "📂 Project Structure:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
find "$SCRIPT_DIR" -maxdepth 2 -type d -name "*" | grep -E "(networking|security|authentication|gpu|virtualization|docker|performance|development|backup|gui-customization|GRUB)" | sort | while read -r dir; do
    dir_name=$(basename "$dir")
    script_count=$(find "$dir" -name "*.sh" -type f | wc -l)
    printf "  📁 %-20s (%d scripts)\n" "$dir_name/" "$script_count"
done
echo ""

echo "═══════════════════════════════════════════════════════════════"
