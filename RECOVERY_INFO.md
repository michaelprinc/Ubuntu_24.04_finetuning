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
