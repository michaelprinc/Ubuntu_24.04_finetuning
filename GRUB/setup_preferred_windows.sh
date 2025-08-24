#!/bin/bash

# Setup Preferred Windows Script
# Configures the available Windows installation as the preferred option

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

# Find available Windows installations
find_windows_installations() {
    log "Finding available Windows installations..."
    
    echo -e "\n${BLUE}Available Windows installations:${NC}"
    
    # Check NTFS partitions and verify they're accessible
    local windows_partitions=()
    while IFS= read -r line; do
        device=$(echo "$line" | awk '{print $1}')
        label=$(echo "$line" | awk '{print $4}')
        uuid=$(echo "$line" | awk '{print $5}')
        mount=$(echo "$line" | awk '{print $7}')
        
        # Check if partition has Windows bootloader indicators
        if [[ -n "$mount" ]]; then
            if find "$mount" -name "bootmgr*" -o -name "Windows" -o -name "Program Files" 2>/dev/null | head -1 | grep -q .; then
                echo -e "${GREEN}✅ $device ($label) - WINDOWS INSTALLATION DETECTED${NC}"
                windows_partitions+=("$device:$label:$uuid:$mount")
            else
                echo -e "${BLUE}ℹ️ $device ($label) - NTFS but no Windows detected${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️ $device ($label) - NOT MOUNTED (will check if mountable)${NC}"
            
            # Try to temporarily mount and check for Windows
            local temp_mount="/tmp/check_windows_$$"
            mkdir -p "$temp_mount"
            if mount -t ntfs-3g "/dev/$device" "$temp_mount" 2>/dev/null; then
                if [[ -d "$temp_mount/Windows" ]] || [[ -f "$temp_mount/bootmgr" ]]; then
                    echo -e "${GREEN}✅ $device ($label) - WINDOWS INSTALLATION FOUND (unmounted)${NC}"
                    windows_partitions+=("$device:$label:$uuid:unmounted")
                fi
                umount "$temp_mount" 2>/dev/null || true
            fi
            rmdir "$temp_mount" 2>/dev/null || true
        fi
    done < <(lsblk -f | grep ntfs)
    
    if [[ ${#windows_partitions[@]} -eq 0 ]]; then
        error "No available Windows installations found"
    fi
    
    echo -e "\nFound ${#windows_partitions[@]} Windows installation(s)"
}

# Mount Windows partitions for analysis
mount_for_analysis() {
    log "Mounting Windows partitions for analysis..."
    
    # Create temporary mount point
    local temp_mount="/tmp/windows_analysis"
    mkdir -p "$temp_mount"
    
    # Check each NTFS partition for Windows (only unmounted ones)
    while IFS= read -r line; do
        device=$(echo "$line" | awk '{print $1}')
        label=$(echo "$line" | awk '{print $4}')
        mount_point=$(echo "$line" | awk '{print $7}')
        
        # Skip already mounted partitions
        if [[ -n "$mount_point" ]]; then
            continue
        fi
        
        log "Analyzing unmounted partition $device ($label)..."
        
        # Try to mount and check for Windows
        if mount -t ntfs-3g "/dev/$device" "$temp_mount" 2>/dev/null; then
            if [[ -d "$temp_mount/Windows" ]] || [[ -f "$temp_mount/bootmgr" ]]; then
                echo -e "${GREEN}✅ $device contains Windows installation${NC}"
                echo "   Found: $(ls -1 "$temp_mount" | grep -E "(Windows|Program|Users)" | head -3 | tr '\n' ' ')"
            else
                echo -e "${BLUE}ℹ️ $device is NTFS but no Windows detected${NC}"
            fi
            umount "$temp_mount" 2>/dev/null || true
        else
            echo -e "${YELLOW}⚠️ Could not mount $device for analysis${NC}"
        fi
    done < <(lsblk -f | grep ntfs)
    
    # Cleanup
    rmdir "$temp_mount" 2>/dev/null || true
}

# Configure GRUB for Windows detection
configure_grub_for_windows() {
    log "Configuring GRUB for Windows detection..."
    
    # Backup current configuration
    cp /etc/default/grub /etc/default/grub.backup.$(date +%Y%m%d_%H%M%S)
    
    # Enable OS Prober
    log "Enabling OS Prober for Windows detection..."
    if grep -q "^#GRUB_DISABLE_OS_PROBER=false" /etc/default/grub; then
        sed -i 's/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
        success "Enabled OS Prober"
    elif grep -q "^GRUB_DISABLE_OS_PROBER=true" /etc/default/grub; then
        sed -i 's/^GRUB_DISABLE_OS_PROBER=true/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
        success "Enabled OS Prober"
    elif ! grep -q "GRUB_DISABLE_OS_PROBER" /etc/default/grub; then
        echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
        success "Added OS Prober configuration"
    else
        success "OS Prober already enabled"
    fi
    
    # Configure boot timeout to show menu
    log "Configuring boot menu timeout..."
    if grep -q "^GRUB_TIMEOUT=0" /etc/default/grub; then
        sed -i 's/^GRUB_TIMEOUT=0/GRUB_TIMEOUT=10/' /etc/default/grub
        success "Set boot timeout to 10 seconds"
    elif grep -q "^GRUB_TIMEOUT=" /etc/default/grub; then
        success "Boot timeout already configured"
    else
        echo "GRUB_TIMEOUT=10" >> /etc/default/grub
        success "Added boot timeout configuration"
    fi
    
    # Configure timeout style
    if grep -q "^GRUB_TIMEOUT_STYLE=hidden" /etc/default/grub; then
        sed -i 's/^GRUB_TIMEOUT_STYLE=hidden/GRUB_TIMEOUT_STYLE=menu/' /etc/default/grub
        success "Changed timeout style to show menu"
    elif ! grep -q "GRUB_TIMEOUT_STYLE" /etc/default/grub; then
        echo "GRUB_TIMEOUT_STYLE=menu" >> /etc/default/grub
        success "Added timeout style configuration"
    fi
    
    # Set default boot option
    log "Configuring default boot option..."
    if grep -q "^GRUB_DEFAULT=" /etc/default/grub; then
        sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=0/' /etc/default/grub
        success "Set Ubuntu as default (first option)"
    else
        echo "GRUB_DEFAULT=0" >> /etc/default/grub
        success "Added default boot configuration"
    fi
}

# Configure EFI boot order for preferred Windows
configure_efi_boot_order() {
    log "Configuring EFI boot order..."
    
    if ! command -v efibootmgr &> /dev/null; then
        warning "efibootmgr not available - skipping EFI configuration"
        return
    fi
    
    # Get list of available partition UUIDs to filter out missing disks
    local available_partuuids=()
    while IFS= read -r line; do
        if [[ $line =~ PARTUUID=\"([^\"]+)\" ]]; then
            partuuid=$(echo "${BASH_REMATCH[1]}" | tr '[:upper:]' '[:lower:]')
            available_partuuids+=("$partuuid")
        fi
    done < <(sudo blkid)
    
    # Find Ubuntu and available Windows entries
    local ubuntu_entry=""
    local windows_entries=()
    
    while IFS= read -r line; do
        boot_num=$(echo "$line" | grep -o "Boot[0-9]\+" | grep -o "[0-9]\+")
        if echo "$line" | grep -q "Ubuntu"; then
            ubuntu_entry="$boot_num"
        elif echo "$line" | grep -q "Windows"; then
            # Check if this Windows entry points to an available disk
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
                    windows_entries+=("$boot_num")
                fi
            fi
        fi
    done < <(efibootmgr)
    
    if [[ -n "$ubuntu_entry" ]] && [[ ${#windows_entries[@]} -gt 0 ]]; then
        # Create new boot order: Ubuntu first, then available Windows
        local new_order="$ubuntu_entry"
        for entry in "${windows_entries[@]}"; do
            new_order+=",$entry"
        done
        
        # Add other entries
        while IFS= read -r line; do
            boot_num=$(echo "$line" | grep -o "Boot[0-9]\+" | grep -o "[0-9]\+")
            if [[ "$boot_num" != "$ubuntu_entry" ]] && [[ ! " ${windows_entries[*]} " =~ " $boot_num " ]]; then
                new_order+=",$boot_num"
            fi
        done < <(efibootmgr | grep "^Boot[0-9]")
        
        log "Setting boot order: $new_order"
        efibootmgr -o "$new_order"
        success "Updated EFI boot order (excluded missing disks)"
    else
        warning "Could not determine optimal boot order"
    fi
}

# Install additional utilities
install_utilities() {
    log "Installing additional utilities..."
    
    # Install OS Prober if not present
    if ! command -v os-prober &> /dev/null; then
        log "Installing os-prober..."
        apt update -qq
        apt install -y os-prober
        success "Installed os-prober"
    else
        success "os-prober already installed"
    fi
    
    # Install ntfs-3g for better Windows partition support
    if ! command -v ntfs-3g &> /dev/null; then
        log "Installing ntfs-3g..."
        apt install -y ntfs-3g
        success "Installed ntfs-3g"
    else
        success "ntfs-3g already installed"
    fi
}

# Main execution
main() {
    echo -e "${BLUE}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║             Setup Preferred Windows Script                  ║
║        Configure Available Windows as Preferred Option      ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    check_root
    find_windows_installations
    mount_for_analysis
    install_utilities
    configure_grub_for_windows
    configure_efi_boot_order
    
    echo -e "\n${GREEN}Windows preference configuration completed!${NC}"
    echo -e "${YELLOW}Next step: Run './regenerate_grub.sh' to update GRUB${NC}"
}

# Run main function
main "$@"
