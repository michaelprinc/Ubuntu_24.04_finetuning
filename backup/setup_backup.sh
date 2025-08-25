#!/bin/bash

# Ubuntu 24.04.3 Backup & Resilience Setup
# Implements Timeshift snapshots and backup strategies

set -e

echo "=== 8. Backup & Resilience Setup ==="

# Install Timeshift
if command -v timeshift >/dev/null 2>&1; then
    echo "Timeshift is already installed"
    timeshift --version
else
    echo "Installing Timeshift..."
    sudo apt update
    sudo apt install -y timeshift
fi

# Check available storage devices
echo "Available storage devices:"
lsblk -f

# Configure Timeshift
echo "Configuring Timeshift..."

# Create Timeshift configuration directory
sudo mkdir -p /etc/timeshift

# Create basic Timeshift configuration
sudo tee /etc/timeshift/timeshift.json > /dev/null << 'EOF'
{
  "backup_device_uuid" : "",
  "parent_device_uuid" : "",
  "do_first_run" : "false",
  "btrfs_mode" : "false",
  "include_btrfs_home_for_backup" : "false",
  "include_btrfs_home_for_restore" : "false",
  "stop_cron_emails" : "true",
  "schedule_monthly" : "false",
  "schedule_weekly" : "true",
  "schedule_daily" : "false",
  "schedule_hourly" : "false",
  "schedule_boot" : "false",
  "count_monthly" : "2",
  "count_weekly" : "3",
  "count_daily" : "5",
  "count_hourly" : "6",
  "count_boot" : "5",
  "snapshot_size" : "0",
  "snapshot_count" : "0",
  "date_format" : "%Y-%m-%d %H:%M:%S",
  "exclude" : [
    "/dev/*",
    "/proc/*",
    "/sys/*",
    "/tmp/*",
    "/run/*",
    "/mnt/*",
    "/media/*",
    "/lost+found",
    "/home/*/.cache/**",
    "/home/*/.local/share/Trash/**",
    "/home/*/.gvfs",
    "/home/*/.mozilla/firefox/*/Cache",
    "/home/*/.mozilla/firefox/*/cache2",
    "/home/*/Downloads/**",
    "/var/cache/**",
    "/var/tmp/**",
    "/var/log/**"
  ],
  "exclude_apps" : []
}
EOF

# Create backup directories
echo "Creating backup directory structure..."
sudo mkdir -p /backup/{system,home,docker,configs}

# Backup scripts are available in this directory:
# - system_backup.sh - Comprehensive system backup utility
# - (Additional backup scripts as needed)
#!/bin/bash
# System Backup Script

BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d_%H%M%S)

case "$1" in
    "full")
        echo "=== Full System Backup ==="
        
        # Create Timeshift snapshot
        echo "Creating Timeshift snapshot..."
        sudo timeshift --create --comments "Full system backup - $DATE"
        
        # Backup important configs
        echo "Backing up system configurations..."
        sudo tar -czf "$BACKUP_DIR/configs/system_configs_$DATE.tar.gz" \
            /etc/fstab \
            /etc/default/grub \
            /etc/apt/sources.list* \
            /etc/docker/daemon.json \
            /etc/timeshift/timeshift.json \
            /etc/modprobe.d/ \
            /etc/systemd/system/ \
            2>/dev/null || true
        
        # Backup home directory (excluding large files)
        echo "Backing up home directory..."
        tar -czf "$BACKUP_DIR/home/home_backup_$DATE.tar.gz" \
            --exclude="$HOME/.cache" \
            --exclude="$HOME/.local/share/Trash" \
            --exclude="$HOME/Downloads" \
            --exclude="$HOME/.mozilla/firefox/*/Cache*" \
            --exclude="$HOME/.steam" \
            --exclude="$HOME/.wine" \
            "$HOME" 2>/dev/null || true
        
        echo "Full backup completed: $DATE"
        ;;
        
    "docker")
        echo "=== Docker Backup ==="
        
        # Stop Docker containers
        echo "Stopping Docker containers..."
        docker stop $(docker ps -q) 2>/dev/null || true
        
        # Backup Docker volumes
        echo "Backing up Docker volumes..."
        sudo tar -czf "$BACKUP_DIR/docker/docker_volumes_$DATE.tar.gz" \
            /var/lib/docker/volumes/ 2>/dev/null || true
        
        # Backup Docker images (optional - can be large)
        # docker save $(docker images -q) | gzip > "$BACKUP_DIR/docker/docker_images_$DATE.tar.gz"
        
        # Restart containers
        echo "Restarting Docker containers..."
        docker start $(docker ps -aq) 2>/dev/null || true
        
        echo "Docker backup completed: $DATE"
        ;;
        
    "quick")
        echo "=== Quick Backup ==="
        
        # Backup essential configs only
        sudo tar -czf "$BACKUP_DIR/configs/quick_backup_$DATE.tar.gz" \
            ~/.bashrc \
            ~/.zshrc \
            ~/.gitconfig \
            ~/.ssh/ \
            ~/.vscode/ \
            2>/dev/null || true
        
        echo "Quick backup completed: $DATE"
        ;;
        
    "list")
        echo "=== Available Backups ==="
        echo "Timeshift snapshots:"
        sudo timeshift --list
        
        echo ""
        echo "Manual backups:"
        ls -la "$BACKUP_DIR"/*/ 2>/dev/null || echo "No manual backups found"
        ;;
        
    "restore")
        echo "=== Restore Options ==="
        echo "To restore from Timeshift:"
        echo "sudo timeshift --restore"
        echo ""
        echo "To restore configs:"
        echo "tar -xzf /backup/configs/system_configs_YYYYMMDD_HHMMSS.tar.gz -C /"
        echo ""
        echo "To restore home:"
        echo "tar -xzf /backup/home/home_backup_YYYYMMDD_HHMMSS.tar.gz -C /"
        ;;
        
    "cleanup")
        echo "=== Cleanup Old Backups ==="
        
        # Keep only last 7 manual backups
        find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete 2>/dev/null || true
        
        # Cleanup Timeshift (keep last 5)
        sudo timeshift --delete-all --keep 5
        
        echo "Cleanup completed"
        ;;
        
    *)
        echo "Usage: $0 {full|docker|quick|list|restore|cleanup}"
        echo "  full     - Create full system backup with Timeshift + configs + home"
        echo "  docker   - Backup Docker volumes and containers"
        echo "  quick    - Backup essential configurations only"
        echo "  list     - List available backups"
        echo "  restore  - Show restore instructions"
        echo "  cleanup  - Remove old backups"
        exit 1
        ;;
esac
EOF

chmod +x /media/michael-princ/E85AE8F65AE8C284/Data_science_projects/Ubuntu_24.04_fine_tuning/scripts/system_backup.sh

# Create cron job for automated backups
echo "Setting up automated backup schedule..."
(crontab -l 2>/dev/null; echo "0 2 * * 0 /media/michael-princ/E85AE8F65AE8C284/Data_science_projects/Ubuntu_24.04_fine_tuning/scripts/system_backup.sh quick") | crontab -

# Create Docker volume backup strategy
echo "Configuring Docker volume backup..."

# Create Docker volume backup script
tee /media/michael-princ/E85AE8F65AE8C284/Data_science_projects/Ubuntu_24.04_fine_tuning/scripts/docker_volume_backup.sh > /dev/null << 'EOF'
#!/bin/bash
# Docker Volume Backup Script

BACKUP_DIR="/backup/docker"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p "$BACKUP_DIR"

# List all Docker volumes
echo "=== Docker Volumes ==="
docker volume ls

echo ""
echo "Creating backup of all Docker volumes..."

# Backup each volume
for volume in $(docker volume ls -q); do
    echo "Backing up volume: $volume"
    docker run --rm \
        -v "$volume":/source:ro \
        -v "$BACKUP_DIR":/backup \
        ubuntu \
        tar czf "/backup/${volume}_${DATE}.tar.gz" -C /source .
done

echo "Docker volume backup completed"
EOF

chmod +x /media/michael-princ/E85AE8F65AE8C284/Data_science_projects/Ubuntu_24.04_fine_tuning/scripts/docker_volume_backup.sh

# Check filesystem for Btrfs/ZFS
echo "Checking filesystem types..."
df -T | grep -E "(btrfs|zfs)" || echo "No Btrfs or ZFS filesystems detected"

# Create recovery information file
tee /media/michael-princ/E85AE8F65AE8C284/Data_science_projects/Ubuntu_24.04_fine_tuning/RECOVERY_INFO.md > /dev/null << 'EOF'
# System Recovery Information

## Backup Strategy

### Timeshift Snapshots
- **Location**: System snapshots stored on root filesystem
- **Schedule**: Weekly snapshots, keeping 3 recent ones
- **Restore**: `sudo timeshift --restore`

### Manual Backups
- **Location**: `/backup/` directory
- **Types**: 
  - System configs: `/backup/configs/`
  - Home directory: `/backup/home/`
  - Docker volumes: `/backup/docker/`

### Automated Schedule
- **Weekly**: Full system backup (Sunday 2:00 AM)
- **Daily**: Quick config backup (cron job)

## Recovery Procedures

### Complete System Recovery
1. Boot from Ubuntu Live USB
2. Install Timeshift: `sudo apt install timeshift`
3. Restore: `sudo timeshift --restore`
4. Reboot and verify

### Config Recovery
```bash
# Extract configs
sudo tar -xzf /backup/configs/system_configs_DATE.tar.gz -C /

# Restart affected services
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### Docker Recovery
```bash
# Restore Docker volumes
sudo systemctl stop docker
sudo tar -xzf /backup/docker/docker_volumes_DATE.tar.gz -C /
sudo systemctl start docker
```

### Home Directory Recovery
```bash
# Restore home (be careful with existing files)
tar -xzf /backup/home/home_backup_DATE.tar.gz -C /tmp/
cp -r /tmp/home/username/* ~/
```

## Important Files to Backup
- `/etc/fstab` - Filesystem mounts
- `/etc/default/grub` - Boot configuration
- `/etc/docker/daemon.json` - Docker configuration
- `/etc/modprobe.d/` - Kernel module configs
- `~/.ssh/` - SSH keys
- `~/.gitconfig` - Git configuration
- VS Code settings and extensions

## Emergency Contacts
- Backup location: `/backup/`
- Recovery scripts: `scripts/system_backup.sh`
- This file: `RECOVERY_INFO.md`
EOF

# Test Timeshift
echo "Testing Timeshift..."
sudo timeshift --check

echo "=== Backup & Resilience Status ==="
echo "Timeshift status:"
sudo timeshift --list | head -10

echo ""
echo "Backup directory structure:"
ls -la /backup/ 2>/dev/null || echo "Backup directory not yet created"

echo ""
echo "Cron jobs:"
crontab -l | grep backup || echo "No backup cron jobs found"

echo ""
echo "Filesystem types:"
df -T | grep -E "^/dev"

echo "=== Backup & Resilience Setup Complete ==="
echo "Next steps:"
echo "1. Run first backup: ./scripts/system_backup.sh full"
echo "2. Configure Timeshift GUI for additional settings"
echo "3. Test restore procedure in a safe environment"
echo "4. Consider external backup storage for critical data"
echo "5. Review RECOVERY_INFO.md for recovery procedures"
