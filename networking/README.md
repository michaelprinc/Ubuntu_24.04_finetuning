# Networking Configuration

This folder contains scripts for network driver installation and optimization, specifically for Ubuntu 24.04.

## Scripts

- **`setup_drivers.sh`** - Install and configure Realtek RTL8125 2.5GbE drivers with Secure Boot compatibility
- **`setup_drivers_optimized.sh`** - Optimized version of the driver setup
- **`rtl8125_speed_fix.sh`** - Fix speed issues with RTL8125 2.5GbE adapter

## Usage

```bash
# Install basic drivers
./setup_drivers.sh

# Or use optimized version
./setup_drivers_optimized.sh

# Fix speed issues if they occur
./rtl8125_speed_fix.sh
```

## Requirements

- Ubuntu 24.04.3 LTS
- Root/sudo access
- Realtek RTL8125 network adapter

## Notes

- Scripts handle Secure Boot compatibility
- Automatic fallback strategies included
- DKMS support for kernel updates
