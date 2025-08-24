#!/bin/bash

# GRUB Backup Script
# Creates backup of current GRUB configuration before modifications

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

# Create backup directory
BACKUP_DIR="/home/$USER/grub_backup_$(date +%Y%m%d_%H%M%S)"

create_backup() {
    log "Creating GRUB configuration backup..."
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    # Backup GRUB configuration files
    if [[ -f /etc/default/grub ]]; then
        sudo cp /etc/default/grub "$BACKUP_DIR/grub.backup"
        success "Backed up GRUB configuration"
    else
        error "GRUB configuration file not found"
    fi
    
    # Backup GRUB generated config
    if [[ -f /boot/grub/grub.cfg ]]; then
        sudo cp /boot/grub/grub.cfg "$BACKUP_DIR/grub.cfg.backup"
        success "Backed up generated GRUB config"
    else
        warning "Generated GRUB config not found"
    fi
    
    # Backup EFI boot entries
    if command -v efibootmgr &> /dev/null; then
        efibootmgr -v > "$BACKUP_DIR/efi_entries.backup" 2>/dev/null || true
        success "Backed up EFI boot entries"
    else
        warning "efibootmgr not available - EFI entries not backed up"
    fi
    
    # Backup current disk configuration
    lsblk -f > "$BACKUP_DIR/disk_layout.backup"
    fdisk -l > "$BACKUP_DIR/partition_table.backup" 2>/dev/null || sudo fdisk -l > "$BACKUP_DIR/partition_table.backup" 2>/dev/null || true
    
    # Create restore script
    cat > "$BACKUP_DIR/restore.sh" << 'EOF'
#!/bin/bash

# GRUB Restore Script
# Restores GRUB configuration from backup

set -e

BACKUP_DIR="$(dirname "$0")"

echo "Restoring GRUB configuration from backup..."

# Restore GRUB configuration
if [[ -f "$BACKUP_DIR/grub.backup" ]]; then
    sudo cp "$BACKUP_DIR/grub.backup" /etc/default/grub
    echo "✅ Restored GRUB configuration"
else
    echo "❌ GRUB backup not found"
    exit 1
fi

# Update GRUB
echo "Updating GRUB..."
sudo update-grub

echo "✅ GRUB restore completed"
echo "Please reboot to test the restored configuration"
EOF
    
    chmod +x "$BACKUP_DIR/restore.sh"
    
    # Set proper ownership
    sudo chown -R "$USER:$USER" "$BACKUP_DIR"
    
    success "Backup created at: $BACKUP_DIR"
    echo "To restore: cd $BACKUP_DIR && ./restore.sh"
}

# Main execution
main() {
    echo -e "${BLUE}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                    GRUB Backup Utility                      ║
║              Backup Before Configuration Changes            ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    create_backup
    
    echo -e "\n${GREEN}Backup completed successfully!${NC}"
    echo "You can now safely run other GRUB configuration scripts."
}

# Run main function
main "$@"
