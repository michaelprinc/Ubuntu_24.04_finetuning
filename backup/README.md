# Backup and Recovery Configuration

This folder contains scripts for system backup, recovery, and resilience setup.

## Scripts

- **`setup_backup.sh`** - Configure Timeshift snapshots and backup strategies
- **`system_backup.sh`** - Create comprehensive system backups

## Usage

```bash
# Setup backup system
./setup_backup.sh

# Create full system backup
./system_backup.sh full

# Create incremental backup
./system_backup.sh incremental

# Restore from backup
./system_backup.sh restore
```

## Features

- Timeshift snapshot configuration
- Automated backup scheduling
- System configuration backup
- Home directory backup
- Incremental backup support
- Recovery procedures

## Requirements

- Ubuntu 24.04.3 LTS
- External storage for backups
- Root/sudo access
- Sufficient disk space

## Notes

- Automated snapshot creation
- Configurable backup schedules
- Excludes cache and temporary files
- Includes restoration procedures
- System resilience testing
