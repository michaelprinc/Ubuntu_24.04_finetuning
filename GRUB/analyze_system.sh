#!/bin/bash

# GRUB System Analysis Script
# Analyzes current disk configuration and boot entries

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
}

# Check if running as root for EFI operations
check_privileges() {
    if [[ $EUID -eq 0 ]]; then
        warning "Running as root - EFI operations enabled"
    else
        warning "Not running as root - some operations may be limited"
    fi
}

# Analyze disk configuration
analyze_disks() {
    log "Analyzing disk configuration..."
    
    echo -e "\n${BLUE}=== DISK LAYOUT ===${NC}"
    lsblk -f | grep -E "(NAME|nvme|sdb|ntfs|ext4|vfat)"
    
    echo -e "\n${BLUE}=== WINDOWS PARTITIONS ===${NC}"
    lsblk -f | grep ntfs | while read line; do
        device=$(echo "$line" | awk '{print $1}')
        label=$(echo "$line" | awk '{print $4}')
        uuid=$(echo "$line" | awk '{print $5}')
        mount=$(echo "$line" | awk '{print $7}')
        
        if [[ -n "$mount" ]]; then
            echo -e "${GREEN}✅ $device ($label) - MOUNTED at $mount${NC}"
        else
            echo -e "${YELLOW}⚠️ $device ($label) - NOT MOUNTED${NC}"
        fi
    done
}

# Analyze EFI boot entries
analyze_efi() {
    log "Analyzing EFI boot entries..."
    
    if command -v efibootmgr &> /dev/null; then
        echo -e "\n${BLUE}=== EFI BOOT ENTRIES ===${NC}"
        
        # Get list of available partition UUIDs
        local available_partuuids=()
        while IFS= read -r line; do
            if [[ $line =~ PARTUUID=\"([^\"]+)\" ]]; then
                partuuid=$(echo "${BASH_REMATCH[1]}" | tr '[:upper:]' '[:lower:]')
                available_partuuids+=("$partuuid")
            fi
        done < <(sudo blkid 2>/dev/null || blkid 2>/dev/null)
        
        efibootmgr -v | grep -E "(Boot|Windows|Ubuntu)" | while read line; do
            if echo "$line" | grep -q "Windows"; then
                boot_num=$(echo "$line" | grep -o "Boot[0-9]\+" | grep -o "[0-9]\+")
                
                # Extract PARTUUID from EFI entry (GPT format)
                if [[ $line =~ HD\([0-9]+,GPT,([^,]+), ]]; then
                    entry_partuuid="${BASH_REMATCH[1]}"
                    entry_partuuid=$(echo "$entry_partuuid" | tr '[:upper:]' '[:lower:]')
                    
                    # Check if this PARTUUID exists on any available disk
                    local found=false
                    for available_uuid in "${available_partuuids[@]}"; do
                        if [[ "$entry_partuuid" == "$available_uuid" ]]; then
                            found=true
                            break
                        fi
                    done
                    
                    if [[ "$found" == "true" ]]; then
                        echo -e "${GREEN}✅ Boot$boot_num (AVAILABLE)${NC}"
                    else
                        echo -e "${RED}❌ Boot$boot_num (MISSING DISK - PARTUUID: $entry_partuuid)${NC}"
                    fi
                else
                    echo -e "${YELLOW}⚠️ Boot$boot_num (Cannot parse partition info)${NC}"
                fi
            elif echo "$line" | grep -q "Ubuntu"; then
                echo -e "${GREEN}✅ $line (CURRENT)${NC}"
            else
                echo -e "${BLUE}ℹ️ $line${NC}"
            fi
        done
    else
        warning "efibootmgr not available - install with: sudo apt install efibootmgr"
    fi
}

# Analyze GRUB configuration
analyze_grub() {
    log "Analyzing GRUB configuration..."
    
    echo -e "\n${BLUE}=== GRUB CONFIGURATION ===${NC}"
    
    if [[ -f /etc/default/grub ]]; then
        echo "Current GRUB settings:"
        grep -E "^GRUB_" /etc/default/grub | while read line; do
            if echo "$line" | grep -q "TIMEOUT=0"; then
                echo -e "${YELLOW}⚠️ $line (Hidden boot menu)${NC}"
            elif echo "$line" | grep -q "OS_PROBER"; then
                echo -e "${GREEN}✅ $line${NC}"
            else
                echo -e "${BLUE}ℹ️ $line${NC}"
            fi
        done
    else
        error "GRUB configuration file not found"
    fi
    
    echo -e "\n${BLUE}=== OS PROBER STATUS ===${NC}"
    if grep -q "^#GRUB_DISABLE_OS_PROBER=false" /etc/default/grub; then
        warning "OS Prober is DISABLED (commented out) - Windows detection limited"
    elif grep -q "^GRUB_DISABLE_OS_PROBER=false" /etc/default/grub; then
        success "OS Prober is ENABLED - Windows should be detected"
    else
        warning "OS Prober setting not found - may need to enable"
    fi
}

# Check Windows bootloaders
check_windows_bootloaders() {
    log "Checking for Windows bootloaders..."
    
    echo -e "\n${BLUE}=== WINDOWS BOOTLOADER SEARCH ===${NC}"
    
    # Check EFI partition for Windows bootloaders
    if [[ -d /boot/efi/EFI ]]; then
        find /boot/efi/EFI -name "*.efi" -o -name "*Windows*" -o -name "*Microsoft*" 2>/dev/null | while read bootloader; do
            echo -e "${GREEN}✅ Found: $bootloader${NC}"
        done
        
        echo -e "\nEFI directories:"
        ls -la /boot/efi/EFI/ | while read line; do
            if echo "$line" | grep -iq "microsoft\|windows"; then
                echo -e "${GREEN}✅ $line${NC}"
            else
                echo -e "${BLUE}ℹ️ $line${NC}"
            fi
        done
    else
        error "EFI partition not mounted at /boot/efi"
    fi
}

# Generate recommendations
generate_recommendations() {
    log "Generating recommendations..."
    
    echo -e "\n${BLUE}=== RECOMMENDATIONS ===${NC}"
    
    # Check if OS prober is disabled
    if grep -q "^#GRUB_DISABLE_OS_PROBER=false" /etc/default/grub; then
        echo -e "${YELLOW}⚠️ Enable OS Prober to detect Windows installations${NC}"
        echo "   Run: ./regenerate_grub.sh"
    fi
    
    # Check for unavailable EFI entries using PARTUUID detection
    local has_missing_entries=false
    local available_partuuids=()
    while IFS= read -r line; do
        if [[ $line =~ PARTUUID=\"([^\"]+)\" ]]; then
            partuuid=$(echo "${BASH_REMATCH[1]}" | tr '[:upper:]' '[:lower:]')
            available_partuuids+=("$partuuid")
        fi
    done < <(sudo blkid 2>/dev/null || blkid 2>/dev/null)
    
    while IFS= read -r line; do
        if echo "$line" | grep -q "Windows"; then
            if [[ $line =~ HD\([0-9]+,GPT,([^,]+), ]]; then
                entry_partuuid="${BASH_REMATCH[1]}"
                entry_partuuid=$(echo "$entry_partuuid" | tr '[:upper:]' '[:lower:]')
                
                local found=false
                for available_uuid in "${available_partuuids[@]}"; do
                    if [[ "$entry_partuuid" == "$available_uuid" ]]; then
                        found=true
                        break
                    fi
                done
                
                if [[ "$found" == "false" ]]; then
                    has_missing_entries=true
                    break
                fi
            fi
        fi
    done < <(efibootmgr -v 2>/dev/null)
    
    if [[ "$has_missing_entries" == "true" ]]; then
        echo -e "${RED}❌ Remove EFI entries for missing disks${NC}"
        echo "   Run: sudo ./disable_unavailable_windows.sh"
    fi
    
    # Check boot timeout
    if grep -q "GRUB_TIMEOUT=0" /etc/default/grub; then
        echo -e "${YELLOW}⚠️ Consider increasing boot timeout to see boot menu${NC}"
        echo "   Run: sudo ./setup_preferred_windows.sh"
    fi
    
    # Check for available Windows installations
    local windows_count=$(lsblk -f | grep ntfs | wc -l)
    if [[ $windows_count -gt 1 ]]; then
        echo -e "${GREEN}✅ Multiple Windows installations detected - set preferred${NC}"
        echo "   Run: sudo ./setup_preferred_windows.sh"
    fi
}

# Main execution
main() {
    echo -e "${BLUE}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                  GRUB System Analysis                       ║
║            Dual Windows Configuration Scanner               ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    check_privileges
    analyze_disks
    analyze_efi
    analyze_grub
    check_windows_bootloaders
    generate_recommendations
    
    echo -e "\n${GREEN}Analysis complete!${NC}"
    echo "Review recommendations above and run appropriate scripts."
}

# Run main function
main "$@"
