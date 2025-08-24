# GRUB Configuration Management

This folder contains scripts to manage GRUB configuration for a dual Windows 11 setup where one disk is no longer available.

## Current System Analysis

Based on your system scan:

### Active Disks:
- **nvme0n1**: Lexar NM790 2TB (Ubuntu + Windows)
  - nvme0n1p3: Ubuntu root partition (ext4)
  - nvme0n1p4: EFI boot partition
  - nvme0n1p2: Windows 11 (ntfs, 1.7TB)

- **nvme1n1**: Kingston SKC2500M81000G (Windows only)
  - nvme1n1p2: Windows 11 (ntfs, 931GB) - Available

- **sdb**: Samsung SSD 870 EVO (Windows only)
  - sdb4: Windows 11 (ntfs, 930GB) - Available

### Missing Disk:
- **ADATA SU650 SSD**: **PHYSICALLY REMOVED**
  - Had Windows 11 installation
  - EFI Boot0000 points to this missing disk (PARTUUID: 31a82e0f-257b-473c-927c-91c90bf16026)

### Boot Entries Found:
- Boot0000: Windows Boot Manager (**MISSING DISK** - ADATA SU650)
- Boot0001: Ubuntu (current boot)
- Boot0002: Windows Boot Manager (Samsung SSD - available)

## Scripts Available:

1. **`analyze_system.sh`** - Scan and analyze current disk/boot configuration
2. **`disable_unavailable_windows.sh`** - Remove EFI entries for disconnected Windows disk
3. **`regenerate_grub.sh`** - Rebuild GRUB with proper Windows detection
4. **`backup_grub.sh`** - Create backup of current GRUB configuration
5. **`restore_grub.sh`** - Restore GRUB from backup
6. **`setup_preferred_windows.sh`** - Set available Windows disk as preferred

## Usage:

```bash
# 1. First, backup current configuration
./backup_grub.sh

# 2. Analyze current system
./analyze_system.sh

# 3. Disable unavailable Windows entries
./disable_unavailable_windows.sh

# 4. Set preferred Windows disk
./setup_preferred_windows.sh

# 5. Regenerate GRUB configuration
./regenerate_grub.sh
```

## Safety Notes:

- All scripts create backups before making changes
- Test boot functionality after each major change
- Keep a live USB handy for recovery if needed
- EFI changes require root privileges

## Recovery:

If boot issues occur:
1. Boot from live USB
2. Mount your Ubuntu partition
3. Run `./restore_grub.sh` to restore previous configuration
