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
