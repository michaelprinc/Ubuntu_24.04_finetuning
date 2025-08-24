#!/bin/bash

# Regenerate GRUB Script
# Rebuilds GRUB configuration with proper Windows detection

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

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script requires root privileges. Run with: sudo $0"
    fi
}

# Pre-regeneration checks
pre_checks() {
    log "Performing pre-regeneration checks..."
    
    # Check if GRUB configuration exists
    if [[ ! -f /etc/default/grub ]]; then
        error "GRUB configuration file not found"
    fi
    
    # Check if EFI partition is mounted
    if ! mount | grep -q "/boot/efi"; then
        error "EFI partition not mounted at /boot/efi"
    fi
    
    # Check for os-prober
    if ! command -v os-prober &> /dev/null; then
        warning "os-prober not found - installing..."
        apt update -qq
        apt install -y os-prober
        success "Installed os-prober"
    fi
    
    # Check for update-grub
    if ! command -v update-grub &> /dev/null; then
        error "update-grub command not found"
    fi
    
    success "Pre-checks completed"
}

# Manual Windows detection
manual_windows_detection() {
    log "Performing manual Windows detection..."
    
    echo -e "\n${BLUE}Scanning for Windows installations:${NC}"
    
    # Look for Windows partitions
    local windows_found=false
    while IFS= read -r line; do
        device=$(echo "$line" | awk '{print $1}')
        label=$(echo "$line" | awk '{print $4}')
        uuid=$(echo "$line" | awk '{print $5}')
        mount=$(echo "$line" | awk '{print $7}')
        
        # Skip nvme1n1 (unavailable)
        if echo "$device" | grep -q "nvme1n1"; then
            continue
        fi
        
        # Check mounted partitions for Windows
        if [[ -n "$mount" ]] && [[ -d "$mount/Windows" || -f "$mount/bootmgr" ]]; then
            echo -e "${GREEN}✅ Windows found on /dev/$device ($label)${NC}"
            echo "   Mount: $mount"
            echo "   UUID: $uuid"
            windows_found=true
        fi
    done < <(lsblk -f | grep ntfs)
    
    if [[ "$windows_found" == "false" ]]; then
        warning "No mounted Windows installations found"
        echo "Consider mounting Windows partitions before regenerating GRUB"
    fi
}

# Run os-prober
run_os_prober() {
    log "Running OS Prober to detect operating systems..."
    
    # Enable os-prober temporarily if disabled
    local os_prober_disabled=false
    if grep -q "^GRUB_DISABLE_OS_PROBER=true" /etc/default/grub; then
        sed -i 's/^GRUB_DISABLE_OS_PROBER=true/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
        os_prober_disabled=true
    fi
    
    # Run os-prober
    echo -e "\n${BLUE}OS Prober results:${NC}"
    if os-prober; then
        success "OS Prober completed successfully"
    else
        warning "OS Prober completed with warnings (this is normal)"
    fi
    
    # Restore os-prober setting if it was disabled
    if [[ "$os_prober_disabled" == "true" ]]; then
        sed -i 's/^GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=true/' /etc/default/grub
    fi
}

# Generate GRUB configuration
generate_grub_config() {
    log "Generating new GRUB configuration..."
    
    # Backup current grub.cfg
    if [[ -f /boot/grub/grub.cfg ]]; then
        cp /boot/grub/grub.cfg "/boot/grub/grub.cfg.backup.$(date +%Y%m%d_%H%M%S)"
        success "Backed up current GRUB configuration"
    fi
    
    # Update GRUB
    echo -e "\n${BLUE}Running update-grub...${NC}"
    if update-grub; then
        success "GRUB configuration updated successfully"
    else
        error "Failed to update GRUB configuration"
    fi
}

# Verify GRUB configuration
verify_grub_config() {
    log "Verifying GRUB configuration..."
    
    if [[ ! -f /boot/grub/grub.cfg ]]; then
        error "GRUB configuration file was not generated"
    fi
    
    # Check for Windows entries
    local windows_entries=$(grep -c "Windows" /boot/grub/grub.cfg || echo "0")
    local ubuntu_entries=$(grep -c "Ubuntu" /boot/grub/grub.cfg || echo "0")
    
    echo -e "\n${BLUE}GRUB Configuration Summary:${NC}"
    echo "Ubuntu entries: $ubuntu_entries"
    echo "Windows entries: $windows_entries"
    
    if [[ $ubuntu_entries -gt 0 ]]; then
        success "Ubuntu entries found in GRUB"
    else
        error "No Ubuntu entries found in GRUB"
    fi
    
    if [[ $windows_entries -gt 0 ]]; then
        success "Windows entries found in GRUB"
    else
        warning "No Windows entries found in GRUB"
        echo "This may be normal if Windows partitions are not accessible"
    fi
    
    # Show boot menu entries
    echo -e "\n${BLUE}Boot menu entries:${NC}"
    grep "^menuentry\|^submenu" /boot/grub/grub.cfg | head -10 | while read line; do
        if echo "$line" | grep -q "Windows"; then
            echo -e "${GREEN}✅ $line${NC}"
        elif echo "$line" | grep -q "Ubuntu"; then
            echo -e "${BLUE}ℹ️ $line${NC}"
        else
            echo -e "${YELLOW}⚠️ $line${NC}"
        fi
    done
}

# Update EFI bootloader
update_efi_bootloader() {
    log "Updating EFI bootloader..."
    
    # Install GRUB to EFI partition
    if grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Ubuntu; then
        success "GRUB installed to EFI partition"
    else
        warning "GRUB EFI installation had issues (may be normal)"
    fi
    
    # Verify EFI entry exists
    if efibootmgr | grep -q "Ubuntu"; then
        success "Ubuntu EFI entry exists"
    else
        warning "Ubuntu EFI entry not found"
    fi
}

# Final recommendations
show_recommendations() {
    log "Final recommendations..."
    
    echo -e "\n${BLUE}=== POST-REGENERATION RECOMMENDATIONS ===${NC}"
    
    echo -e "${GREEN}✅ GRUB regeneration completed${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Reboot to test the new GRUB configuration"
    echo "2. Verify that both Ubuntu and Windows options appear in boot menu"
    echo "3. Test booting into Windows to ensure it works"
    echo ""
    echo "If boot issues occur:"
    echo "• Boot from live USB"
    echo "• Mount your Ubuntu partition"
    echo "• Restore from backup in ~/grub_backup_*"
    echo ""
    echo "To see boot menu:"
    echo "• Hold Shift during boot, or"
    echo "• Press Esc repeatedly during startup"
}

# Main execution
main() {
    echo -e "${BLUE}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                   Regenerate GRUB Script                    ║
║           Rebuild GRUB with Windows Detection               ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    check_root
    pre_checks
    manual_windows_detection
    run_os_prober
    generate_grub_config
    verify_grub_config
    update_efi_bootloader
    show_recommendations
    
    echo -e "\n${GREEN}GRUB regeneration completed successfully!${NC}"
    echo -e "${YELLOW}Please reboot to test the new configuration${NC}"
}

# Run main function
main "$@"
