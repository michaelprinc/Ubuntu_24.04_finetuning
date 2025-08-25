#!/bin/bash

# Master Setup Script for Ubuntu 24.04 Fine-Tuning
# Updated for thematic organization

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Ubuntu 24.04 Fine-Tuning Setup ==="
echo "Thematic organization - each module can be run independently"
echo ""

# Function to show usage
show_usage() {
    echo "Usage: $0 [module]"
    echo ""
    echo "Available modules:"
    echo "  networking      - Install network drivers (RTL8125)"
    echo "  security        - Security hardening and firewall"
    echo "  authentication - Facial recognition (Howdy) setup"
    echo "  gpu             - GPU drivers and compute stack"
    echo "  virtualization  - KVM/QEMU and GPU passthrough"
    echo "  docker          - Docker installation and setup"
    echo "  performance     - System performance tuning"
    echo "  development     - Developer tools and QoL"
    echo "  backup          - Backup and recovery setup"
    echo "  gui             - GUI customization (Windows-like)"
    echo "  grub            - GRUB configuration"
    echo ""
    echo "  all             - Run all modules (full setup)"
    echo ""
    echo "Example: $0 networking"
    echo "Example: $0 all"
}

# Function to run a module
run_module() {
    local module=$1
    local script_path=""
    
    case $module in
        "networking")
            script_path="$SCRIPT_DIR/networking/setup_drivers.sh"
            ;;
        "security")
            script_path="$SCRIPT_DIR/security/setup_security.sh"
            ;;
        "authentication")
            script_path="$SCRIPT_DIR/authentication/setup_howdy.sh"
            ;;
        "gpu")
            script_path="$SCRIPT_DIR/gpu/setup_gpu_stack.sh"
            ;;
        "virtualization")
            script_path="$SCRIPT_DIR/virtualization/setup_virtualization.sh"
            ;;
        "docker")
            script_path="$SCRIPT_DIR/docker/setup_docker.sh"
            ;;
        "performance")
            script_path="$SCRIPT_DIR/performance/setup_performance.sh"
            ;;
        "development")
            script_path="$SCRIPT_DIR/development/setup_development.sh"
            ;;
        "backup")
            script_path="$SCRIPT_DIR/backup/setup_backup.sh"
            ;;
        "gui")
            script_path="$SCRIPT_DIR/gui-customization/setup_windows_like_gui.sh"
            ;;
        "grub")
            script_path="$SCRIPT_DIR/GRUB/complete_setup.sh"
            ;;
        "help"|"--help"|"-h")
            show_usage
            exit 0
            ;;
        *)
            echo "❌ Unknown module: $module"
            show_usage
            exit 1
            ;;
    esac
    
    if [[ -f "$script_path" ]]; then
        echo "🚀 Running module: $module"
        echo "📄 Script: $script_path"
        echo ""
        
        # Make script executable
        chmod +x "$script_path"
        
        # Run the script
        bash "$script_path"
        
        echo ""
        echo "✅ Module $module completed"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    else
        echo "❌ Script not found: $script_path"
        exit 1
    fi
}

# Main execution
if [[ $# -eq 0 ]]; then
    show_usage
    exit 1
fi

case $1 in
    "all")
        echo "🚀 Running complete Ubuntu 24.04 setup..."
        echo ""
        
        modules=("networking" "security" "authentication" "performance" "gpu" "docker" "virtualization" "development" "backup" "gui" "grub")
        
        for module in "${modules[@]}"; do
            run_module "$module"
        done
        
        echo "🎉 Complete Ubuntu 24.04 setup finished!"
        echo ""
        echo "📖 Check individual module READMEs for usage:"
        echo "   - networking/README.md"
        echo "   - security/README.md"
        echo "   - authentication/README.md"
        echo "   - gpu/README.md"
        echo "   - etc..."
        ;;
    *)
        run_module "$1"
        ;;
esac
