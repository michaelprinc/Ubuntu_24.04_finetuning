#!/bin/bash

# GRUB Complete Setup Script
# Runs the complete GRUB reconfiguration process in the correct order

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
    exit 1
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if all scripts exist
check_scripts() {
    local scripts=(
        "backup_grub.sh"
        "analyze_system.sh"
        "disable_unavailable_windows.sh"
        "setup_preferred_windows.sh"
        "regenerate_grub.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ ! -f "$SCRIPT_DIR/$script" ]]; then
            error "Required script not found: $script"
        fi
        if [[ ! -x "$SCRIPT_DIR/$script" ]]; then
            chmod +x "$SCRIPT_DIR/$script"
        fi
    done
    
    success "All required scripts found"
}

# Interactive mode
interactive_setup() {
    echo -e "${BLUE}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                 GRUB Complete Setup Wizard                  ║
║              Interactive Dual Windows Configuration         ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo "This wizard will:"
    echo "1. Analyze your current system"
    echo "2. Create backups"
    echo "3. Remove unavailable Windows entries"
    echo "4. Configure preferred Windows installation"
    echo "5. Regenerate GRUB configuration"
    echo ""
    
    read -p "Continue with complete setup? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled. You can run individual scripts manually:"
        echo "  ./backup_grub.sh"
        echo "  ./analyze_system.sh"
        echo "  sudo ./disable_unavailable_windows.sh"
        echo "  sudo ./setup_preferred_windows.sh"
        echo "  sudo ./regenerate_grub.sh"
        exit 0
    fi
}

# Step-by-step execution
run_complete_setup() {
    echo -e "\n${BLUE}=== STEP 1: SYSTEM ANALYSIS ===${NC}"
    log "Running system analysis..."
    bash "$SCRIPT_DIR/analyze_system.sh"
    
    echo -e "\n${BLUE}=== STEP 2: BACKUP CREATION ===${NC}"
    log "Creating backups..."
    bash "$SCRIPT_DIR/backup_grub.sh"
    
    echo -e "\n${BLUE}=== STEP 3: DISABLE UNAVAILABLE WINDOWS ===${NC}"
    log "Removing unavailable Windows entries..."
    echo "This step requires root privileges..."
    sudo bash "$SCRIPT_DIR/disable_unavailable_windows.sh"
    
    echo -e "\n${BLUE}=== STEP 4: SETUP PREFERRED WINDOWS ===${NC}"
    log "Configuring preferred Windows installation..."
    sudo bash "$SCRIPT_DIR/setup_preferred_windows.sh"
    
    echo -e "\n${BLUE}=== STEP 5: REGENERATE GRUB ===${NC}"
    log "Regenerating GRUB configuration..."
    sudo bash "$SCRIPT_DIR/regenerate_grub.sh"
}

# Final verification
final_verification() {
    echo -e "\n${BLUE}=== FINAL VERIFICATION ===${NC}"
    log "Running final system analysis..."
    bash "$SCRIPT_DIR/analyze_system.sh"
    
    echo -e "\n${GREEN}=== SETUP COMPLETE ===${NC}"
    echo ""
    echo "✅ GRUB has been reconfigured for your dual Windows setup"
    echo "✅ Unavailable Windows disk entries have been removed"
    echo "✅ Available Windows installation has been configured as preferred"
    echo "✅ Backups have been created in ~/grub_backup_*"
    echo ""
    echo -e "${YELLOW}IMPORTANT: Please reboot to test the new configuration${NC}"
    echo ""
    echo "After reboot:"
    echo "• You should see a boot menu with Ubuntu and available Windows options"
    echo "• Ubuntu will be the default (first) option"
    echo "• Boot menu will show for 10 seconds"
    echo ""
    echo "If you encounter issues:"
    echo "• Boot from live USB"
    echo "• Run the restore script from your backup directory"
    echo "• Or restore individual components manually"
}

# Quick setup mode (non-interactive)
quick_setup() {
    echo -e "${BLUE}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                    GRUB Quick Setup                         ║
║              Automated Dual Windows Configuration           ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    warning "Quick setup mode - minimal user interaction"
    
    run_complete_setup
    final_verification
}

# Show help
show_help() {
    echo "GRUB Complete Setup Script"
    echo ""
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  -i, --interactive    Interactive setup with confirmations"
    echo "  -q, --quick         Quick setup with minimal interaction"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Individual scripts:"
    echo "  ./backup_grub.sh                    Create backup"
    echo "  ./analyze_system.sh                 Analyze current setup"
    echo "  sudo ./disable_unavailable_windows.sh   Remove unavailable entries"
    echo "  sudo ./setup_preferred_windows.sh       Configure preferred Windows"
    echo "  sudo ./regenerate_grub.sh               Regenerate GRUB"
}

# Main execution
main() {
    check_scripts
    
    case "${1:-}" in
        -i|--interactive)
            interactive_setup
            run_complete_setup
            final_verification
            ;;
        -q|--quick)
            quick_setup
            ;;
        -h|--help)
            show_help
            ;;
        "")
            interactive_setup
            run_complete_setup
            final_verification
            ;;
        *)
            error "Unknown option: $1. Use -h for help."
            ;;
    esac
}

# Run main function
main "$@"
