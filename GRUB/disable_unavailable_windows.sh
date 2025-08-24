#!/bin/bash

# Disable Unavailable Windows Script
# Removes EFI boot entries for disconnected Windows disk (nvme1n1)

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

# Identify unavailable Windows entries
identify_unavailable() {
    log "Identifying unavailable Windows boot entries..."
    
    if ! command -v efibootmgr &> /dev/null; then
        error "efibootmgr not found. Install with: apt install efibootmgr"
    fi
    
    echo -e "\n${BLUE}Current EFI boot entries:${NC}"
    
    # Get list of available partition UUIDs
    local available_partuuids=()
    while IFS= read -r line; do
        if [[ $line =~ PARTUUID=\"([^\"]+)\" ]]; then
            available_partuuids+=("${BASH_REMATCH[1]}")
        fi
    done < <(sudo blkid)
    
    efibootmgr -v | grep -E "Boot[0-9]+.*Windows" | while read line; do
        boot_num=$(echo "$line" | grep -o "Boot[0-9]\+" | grep -o "[0-9]\+")
        
        # Extract PARTUUID from EFI entry (GPT format: HD(partition,GPT,partuuid,start,size))
        if [[ $line =~ HD\([0-9]+,GPT,([^,]+), ]]; then
            entry_partuuid="${BASH_REMATCH[1]}"
            entry_partuuid=$(echo "$entry_partuuid" | tr '[:upper:]' '[:lower:]')
            
            # Check if this PARTUUID exists on any available disk
            local found=false
            for available_uuid in "${available_partuuids[@]}"; do
                available_uuid=$(echo "$available_uuid" | tr '[:upper:]' '[:lower:]')
                if [[ "$entry_partuuid" == "$available_uuid" ]]; then
                    found=true
                    break
                fi
            done
            
            if [[ "$found" == "true" ]]; then
                echo -e "${GREEN}✅ Boot$boot_num (AVAILABLE - PARTUUID: $entry_partuuid)${NC}"
            else
                echo -e "${RED}❌ Boot$boot_num (UNAVAILABLE - Missing disk with PARTUUID: $entry_partuuid)${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️ Boot$boot_num (Cannot parse partition info)${NC}"
        fi
    done
}

# Remove unavailable Windows entries
remove_unavailable() {
    log "Removing unavailable Windows boot entries..."
    
    # Get list of available partition UUIDs
    local available_partuuids=()
    while IFS= read -r line; do
        if [[ $line =~ PARTUUID=\"([^\"]+)\" ]]; then
            partuuid=$(echo "${BASH_REMATCH[1]}" | tr '[:upper:]' '[:lower:]')
            available_partuuids+=("$partuuid")
        fi
    done < <(sudo blkid)
    
    # Get list of Windows boot entries pointing to missing disks
    local entries_to_remove=()
    while IFS= read -r line; do
        if echo "$line" | grep -q "Windows"; then
            boot_num=$(echo "$line" | grep -o "Boot[0-9]\+" | grep -o "[0-9]\+")
            
            # Extract PARTUUID from EFI entry
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
                
                if [[ "$found" == "false" ]]; then
                    entries_to_remove+=("$boot_num:$entry_partuuid")
                fi
            fi
        fi
    done < <(efibootmgr -v)
    
    if [[ ${#entries_to_remove[@]} -eq 0 ]]; then
        success "No unavailable Windows entries found"
        return
    fi
    
    echo -e "\n${YELLOW}Entries to remove (missing disks):${NC}"
    for entry in "${entries_to_remove[@]}"; do
        boot_num=$(echo "$entry" | cut -d: -f1)
        partuuid=$(echo "$entry" | cut -d: -f2)
        echo "Boot$boot_num - Missing disk with PARTUUID: $partuuid"
        efibootmgr -v | grep "Boot${boot_num}" | head -1
    done
    
    echo -e "\n${RED}WARNING: This will permanently remove EFI boot entries for missing disks!${NC}"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        warning "Operation cancelled by user"
        exit 0
    fi
    
    # Remove the entries
    for entry in "${entries_to_remove[@]}"; do
        boot_num=$(echo "$entry" | cut -d: -f1)
        log "Removing boot entry $boot_num..."
        if efibootmgr -b "$boot_num" -B; then
            success "Removed boot entry $boot_num"
        else
            error "Failed to remove boot entry $boot_num"
        fi
    done
}

# Clean up boot order
cleanup_boot_order() {
    log "Cleaning up boot order..."
    
    # Get current boot order
    current_order=$(efibootmgr | grep "BootOrder:" | cut -d: -f2 | tr -d ' ')
    
    # Get list of existing boot entries
    existing_entries=()
    while IFS= read -r line; do
        if echo "$line" | grep -q "^Boot[0-9]\+"; then
            boot_num=$(echo "$line" | grep -o "Boot[0-9]\+" | grep -o "[0-9]\+")
            existing_entries+=("$boot_num")
        fi
    done < <(efibootmgr)
    
    # Create new boot order with only existing entries
    new_order=""
    IFS=',' read -ra order_array <<< "$current_order"
    for entry in "${order_array[@]}"; do
        entry=$(echo "$entry" | tr -d ' ')
        if [[ " ${existing_entries[*]} " =~ " $entry " ]]; then
            if [[ -n "$new_order" ]]; then
                new_order+=","
            fi
            new_order+="$entry"
        fi
    done
    
    if [[ "$new_order" != "$current_order" ]]; then
        log "Updating boot order: $new_order"
        efibootmgr -o "$new_order"
        success "Boot order updated"
    else
        success "Boot order is already correct"
    fi
}

# Set Ubuntu as default if needed
set_ubuntu_default() {
    log "Checking if Ubuntu should be set as default..."
    
    # Find Ubuntu boot entry
    ubuntu_entry=""
    while IFS= read -r line; do
        if echo "$line" | grep -q "Ubuntu"; then
            ubuntu_entry=$(echo "$line" | grep -o "Boot[0-9]\+" | grep -o "[0-9]\+")
            break
        fi
    done < <(efibootmgr)
    
    if [[ -n "$ubuntu_entry" ]]; then
        current_order=$(efibootmgr | grep "BootOrder:" | cut -d: -f2 | tr -d ' ')
        first_entry=$(echo "$current_order" | cut -d, -f1)
        
        if [[ "$first_entry" != "$ubuntu_entry" ]]; then
            log "Setting Ubuntu as first boot option..."
            # Remove Ubuntu from current position and add to front
            new_order="$ubuntu_entry"
            IFS=',' read -ra order_array <<< "$current_order"
            for entry in "${order_array[@]}"; do
                entry=$(echo "$entry" | tr -d ' ')
                if [[ "$entry" != "$ubuntu_entry" ]]; then
                    new_order+=","
                    new_order+="$entry"
                fi
            done
            
            efibootmgr -o "$new_order"
            success "Ubuntu set as default boot option"
        else
            success "Ubuntu is already the default boot option"
        fi
    else
        warning "Ubuntu boot entry not found"
    fi
}

# Main execution
main() {
    echo -e "${BLUE}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║            Disable Unavailable Windows Script               ║
║          Remove EFI Entries for Disconnected Disk          ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    check_root
    identify_unavailable
    
    echo -e "\n${YELLOW}This script will:${NC}"
    echo "1. Remove EFI boot entries for unavailable Windows disk (nvme1n1)"
    echo "2. Clean up boot order"
    echo "3. Ensure Ubuntu remains as default boot option"
    
    remove_unavailable
    cleanup_boot_order
    set_ubuntu_default
    
    echo -e "\n${GREEN}EFI cleanup completed successfully!${NC}"
    echo "Run './analyze_system.sh' to verify changes"
}

# Run main function
main "$@"
