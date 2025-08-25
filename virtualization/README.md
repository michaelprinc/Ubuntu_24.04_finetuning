# Virtualization Configuration

This folder contains scripts for virtualization setup, KVM/QEMU configuration, and VM management.

## Scripts

- **`setup_virtualization.sh`** - Install and configure KVM, QEMU, and GPU passthrough
- **`start-vm.sh`** - Start Windows VM with GPU passthrough
- **`stop-vm.sh`** - Stop running VMs

## Usage

```bash
# Install virtualization stack
./setup_virtualization.sh

# Start VM with GPU passthrough
./start-vm.sh

# Stop VMs
./stop-vm.sh
```

## Features

- KVM/QEMU installation
- GPU passthrough configuration
- IOMMU setup
- VM management utilities
- Virtual network configuration

## Requirements

- Ubuntu 24.04.3 LTS
- CPU with VT-x/AMD-V support
- IOMMU support in BIOS
- Dedicated GPU for passthrough
- Root/sudo access

## Notes

- Requires BIOS configuration for IOMMU
- GPU passthrough needs two GPUs (host + guest)
- Automatic virtualization feature detection
- Includes safety checks and validation
