# Security Configuration

This folder contains scripts for system security hardening and configurations for Ubuntu 24.04.

## Scripts

- **`setup_security.sh`** - Comprehensive security hardening setup including automatic updates, AppArmor, firewall, and fail2ban

## Usage

```bash
# Run security hardening
./setup_security.sh
```

## Features

- Automatic security updates (unattended-upgrades)
- AppArmor configuration
- UFW firewall setup
- fail2ban installation and configuration
- Security audit tools
- Kernel security parameters

## Requirements

- Ubuntu 24.04.3 LTS
- Root/sudo access
- Internet connection for package downloads

## Notes

- Script configures automatic security updates
- Sets up robust firewall rules
- Enables intrusion detection with fail2ban
- Hardens system against common attack vectors
