#!/bin/bash

# GRUB Recovery Script
# Restores GRUB configuration from backup

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

# Find backup directories
find_backups() {
    log "Searching for GRUB backups..."
    
    local backup_dirs=()
    
    # Look in home directory
    if [[ -d "/home/$USER" ]]; then
        while IFS= read -r -d '' dir; do
            backup_dirs+=("$dir")
        done < <(find "/home/$USER" -maxdepth 1 -type d -name "grub_backup_*" -print0 2>/dev/null)
    fi
    
    # Look in /tmp (if running from live USB)
    while IFS= read -r -d '' dir; do
        backup_dirs+=("$dir")
    done < <(find /tmp -maxdepth 1 -type d -name "grub_backup_*" -print0 2>/dev/null)
    
    if [[ ${#backup_dirs[@]} -eq 0 ]]; then
        error "No GRUB backups found"
    fi
    
    echo -e "\n${BLUE}Available backups:${NC}"
    for i in "${!backup_dirs[@]}"; do
        local dir="${backup_dirs[$i]}"
        local timestamp=$(basename "$dir" | sed 's/grub_backup_//')
        echo "$((i+1)). $dir (created: $timestamp)"
    done
    
    echo ""
    read -p "Select backup to restore (1-${#backup_dirs[@]}): " -r selection
    
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt ${#backup_dirs[@]} ]]; then
        error "Invalid selection"
    fi
    
    BACKUP_DIR="${backup_dirs[$((selection-1))]}"
    success "Selected backup: $BACKUP_DIR"
}

# Verify backup contents
verify_backup() {
    log "Verifying backup contents..."
    
    if [[ ! -f "$BACKUP_DIR/grub.backup" ]]; then
        error "GRUB configuration backup not found in $BACKUP_DIR"
    fi
    
    if [[ ! -f "$BACKUP_DIR/restore.sh" ]]; then
        warning "Restore script not found - using manual restore"
    fi
    
    echo -e "\n${BLUE}Backup contents:${NC}"
    ls -la "$BACKUP_DIR/" | while read line; do
        if echo "$line" | grep -q "grub"; then
            echo -e "${GREEN}✅ $line${NC}"
        elif echo "$line" | grep -q "efi\|disk"; then
            echo -e "${BLUE}ℹ️ $line${NC}"
        else
            echo -e "${YELLOW}⚠️ $line${NC}"
        fi
    done
    
    success "Backup verification completed"
}

# Restore GRUB configuration
restore_grub_config() {
    log "Restoring GRUB configuration..."
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        error "Root privileges required for restoration. Run with: sudo $0"
    fi
    
    # Backup current configuration before restore
    if [[ -f /etc/default/grub ]]; then
        cp /etc/default/grub "/etc/default/grub.pre-restore.$(date +%Y%m%d_%H%M%S)"
        success "Backed up current configuration"
    fi
    
    # Restore GRUB configuration
    if cp "$BACKUP_DIR/grub.backup" /etc/default/grub; then
        success "GRUB configuration restored"
    else
        error "Failed to restore GRUB configuration"
    fi
    
    # Update GRUB
    log "Updating GRUB with restored configuration..."
    if update-grub; then
        success "GRUB updated successfully"
    else
        error "Failed to update GRUB"
    fi
}

# Restore EFI entries (if available)
restore_efi_entries() {
    log "Checking for EFI entries restoration..."
    
    if [[ ! -f "$BACKUP_DIR/efi_entries.backup" ]]; then
        warning "EFI entries backup not found - skipping"
        return
    fi
    
    if ! command -v efibootmgr &> /dev/null; then
        warning "efibootmgr not available - skipping EFI restoration"
        return
    fi
    
    echo -e "\n${BLUE}Current EFI entries:${NC}"
    efibootmgr
    
    echo -e "\n${BLUE}Backed up EFI entries:${NC}"
    cat "$BACKUP_DIR/efi_entries.backup"
    
    echo ""
    warning "EFI entry restoration is complex and may cause boot issues"
    read -p "Attempt to restore EFI entries? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        warning "EFI restoration not implemented - manual intervention required"
        echo "Please compare current and backup EFI entries manually"
    else
        log "Skipping EFI entries restoration"
    fi
}

# Reinstall GRUB bootloader
reinstall_grub_bootloader() {
    log "Reinstalling GRUB bootloader..."
    
    read -p "Reinstall GRUB to EFI partition? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        warning "Skipping GRUB bootloader reinstallation"
        return
    fi
    
    # Check if EFI partition is mounted
    if ! mount | grep -q "/boot/efi"; then
        error "EFI partition not mounted at /boot/efi"
    fi
    
    # Reinstall GRUB
    if grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Ubuntu; then
        success "GRUB bootloader reinstalled"
    else
        error "Failed to reinstall GRUB bootloader"
    fi
}

# Verify restoration
verify_restoration() {
    log "Verifying restoration..."
    
    if [[ ! -f /etc/default/grub ]]; then
        error "GRUB configuration file missing after restoration"
    fi
    
    if [[ ! -f /boot/grub/grub.cfg ]]; then
        error "GRUB menu configuration missing"
    fi
    
    echo -e "\n${BLUE}Restored GRUB configuration:${NC}"
    grep -E "^GRUB_" /etc/default/grub | while read line; do
        echo -e "${GREEN}✅ $line${NC}"
    done
    
    echo -e "\n${BLUE}Boot menu entries:${NC}"
    grep "^menuentry" /boot/grub/grub.cfg | head -5 | while read line; do
        echo -e "${GREEN}✅ $line${NC}"
    done
    
    success "Restoration verification completed"
}

# Show restoration summary
show_summary() {
    echo -e "\n${GREEN}=== RESTORATION COMPLETE ===${NC}"
    echo ""
    echo "✅ GRUB configuration has been restored from backup"
    echo "✅ GRUB menu has been regenerated"
    echo "✅ System should boot with previous configuration"
    echo ""
    echo -e "${YELLOW}IMPORTANT: Reboot now to test the restored configuration${NC}"
    echo ""
    echo "If issues persist:"
    echo "• Try booting with different GRUB options"
    echo "• Use live USB to investigate further"
    echo "• Consider fresh GRUB installation"
    echo ""
    echo "Backup location: $BACKUP_DIR"
}

# Emergency restore (minimal interaction)
emergency_restore() {
    echo -e "${RED}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                    EMERGENCY GRUB RESTORE                   ║
║                 Quick Restoration from Backup               ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    if [[ $EUID -ne 0 ]]; then
        error "Emergency restore requires root privileges. Run with: sudo $0 --emergency"
    fi
    
    # Find the most recent backup
    local latest_backup
    latest_backup=$(find "/home" -maxdepth 2 -type d -name "grub_backup_*" 2>/dev/null | sort | tail -1)
    
    if [[ -z "$latest_backup" ]]; then
        error "No backups found for emergency restore"
    fi
    
    BACKUP_DIR="$latest_backup"
    log "Using latest backup: $BACKUP_DIR"
    
    # Quick restore
    if [[ -f "$BACKUP_DIR/grub.backup" ]]; then
        cp "$BACKUP_DIR/grub.backup" /etc/default/grub
        update-grub
        success "Emergency restore completed"
    else
        error "Backup file not found"
    fi
}

# Show help
show_help() {
    echo "GRUB Recovery Script"
    echo ""
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  --emergency    Emergency restore using latest backup"
    echo "  -h, --help     Show this help message"
    echo ""
    echo "Normal mode will:"
    echo "1. Search for available backups"
    echo "2. Let you select which backup to restore"
    echo "3. Restore GRUB configuration"
    echo "4. Update GRUB menu"
    echo "5. Optionally reinstall bootloader"
}

# Main execution
main() {
    case "${1:-}" in
        --emergency)
            emergency_restore
            ;;
        -h|--help)
            show_help
            ;;
        "")
            echo -e "${BLUE}"
            cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                     GRUB Recovery Tool                      ║
║                 Restore from Backup Configuration           ║
╚══════════════════════════════════════════════════════════════╝
EOF
            echo -e "${NC}"
            
            find_backups
            verify_backup
            restore_grub_config
            restore_efi_entries
            reinstall_grub_bootloader
            verify_restoration
            show_summary
            ;;
        *)
            error "Unknown option: $1. Use -h for help."
            ;;
    esac
}

# Run main function
main "$@"
