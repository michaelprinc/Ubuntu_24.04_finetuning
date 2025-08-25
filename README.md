# Ubuntu 24.04.3 Enhanced Setup

This repository contains comprehensive setup scripts for Ubuntu 24.04.3 with performance optimizations, security hardening, and development tools.

## 🚀 Quick Start

### New Thematic Organization (Recommended)

```bash
# List all available scripts
./list_scripts.sh

# Run complete setup with new thematic organization
./setup_thematic.sh all

# Run individual modules
./setup_thematic.sh networking
./setup_thematic.sh gpu
./setup_thematic.sh docker

# Run specific utilities
./gpu/gpu_monitor.sh
./docker/docker_manage.sh status
./backup/system_backup.sh full
```

### Legacy Quick Start

```bash
# Make the main script executable
chmod +x setup.sh

# Run complete setup (legacy)
./setup.sh

# For Windows users: Make Ubuntu feel like Windows 11
chmod +x gui-customization/setup_windows_like_gui.sh
./gui-customization/setup_windows_like_gui.sh

# Or run individual phases
./setup.sh 1  # Networking only
./setup.sh 4  # GPU setup only
```

## 📋 Implementation Plan

### ✅ 1. Networking & Drivers
- **Realtek r8125 driver** (DKMS installation for kernel survival)
- **NetworkManager DNS caching** via systemd-resolved
- **Ethernet verification** with ethtool

### 🔒 2. Security Hardening
- **Automatic security updates** with unattended-upgrades
- **AppArmor profiles** for Docker/VMs
- **UFW firewall** with secure defaults
- **fail2ban** for SSH brute force protection

### ⚡ 3. Performance & Hardware Acceleration
- **Kernel tuning** with custom tuned profile
- **Low-latency optimizations** (vm.swappiness=10, inotify limits)
- **ZSTD compression** (default in 24.04)
- **Performance monitoring** tools (htop, btop, sysstat)

### 🎮 4. GPU / Compute Stack
- **AMD ROCm** for RX 6800 (RDNA2 support)
- **Vulkan/OpenCL** stack with Mesa drivers
- **GPU monitoring** with radeontop and nvtop
- **Compute libraries** (HIP, OpenCL)

### 🖥️ 5. Virtualization & GPU Passthrough
- **KVM + QEMU + Virt-Manager** stack
- **GPU passthrough** configuration for RX 6800 → Windows
- **VFIO setup** with IOMMU configuration
- **VM management scripts** (start-vm.sh, stop-vm.sh)

### 🐳 6. Docker & Development
- **Docker CE** with buildkit optimizations
- **cgroup v2** support (Ubuntu 24.04 default)
- **Resource limits** and performance tuning
- **Multi-container examples** (Nginx + WordPress + WireGuard)

### 🧑‍💻 7. Developer Quality of Life
- **VS Code** with workspace configuration
- **GitHub CLI** integration
- **Zsh + Oh My Zsh** with productivity plugins
- **Modern CLI tools** (exa, bat, fd, ripgrep, btop)

### 🎨 8. GUI Customization (Windows 11-like Experience)
- **Desktop icons** support (missing "Pin to Desktop" feature)
- **Windows-style taskbar** and start menu (Dash to Panel + ArcMenu)
- **Windows 11 themes** and icon packs (WhiteSur, Fluent)
- **Familiar keyboard shortcuts** (Super+R, Super+E, etc.)
- **File manager improvements** (Nemo with Windows-like features)
- **Productivity tips** for Windows users transitioning to Ubuntu

### 📦 9. Backup & Resilience
- **Timeshift snapshots** with automated scheduling
- **System backup scripts** for /etc, /home, Docker volumes
- **Recovery procedures** documentation
- **Automated cleanup** of old backups

## 🛠️ Usage

### Thematic Modules

Scripts are now organized into thematic folders for better organization:

```bash
# Networking Configuration
cd networking/
./setup_drivers.sh              # Install Realtek RTL8125 drivers
./rtl8125_speed_fix.sh          # Fix speed issues

# Security Configuration
cd security/
./setup_security.sh            # Complete security hardening

# Authentication Methods
cd authentication/
./setup_howdy.sh               # Install facial recognition (Howdy)
./howdy_manage.sh status       # Manage Howdy settings
./howdy_manage.sh enable       # Enable facial recognition
./howdy_manage.sh disable      # Disable facial recognition
./howdy_rollback.sh            # Complete Howdy removal

# GPU Configuration
cd gpu/
./setup_gpu_stack.sh           # Install AMD ROCm and Vulkan
./gpu_monitor.sh               # Monitor GPU status

# Virtualization Setup
cd virtualization/
./setup_virtualization.sh      # Install KVM/QEMU
./start-vm.sh                  # Start VM with GPU passthrough
./stop-vm.sh                   # Stop VMs

# Docker Environment
cd docker/
./setup_docker.sh              # Install Docker CE
./docker_manage.sh status      # Docker status
./docker_manage.sh cleanup     # Clean up resources

# Performance Tuning
cd performance/
./setup_performance.sh         # System performance optimization

# Development Tools
cd development/
./setup_development.sh         # Install dev tools
./shell_recovery.sh            # Shell recovery utilities

# Backup & Recovery
cd backup/
./setup_backup.sh              # Configure backup system
./system_backup.sh full        # Create system backup

# GUI Customization
cd gui-customization/
./setup_windows_like_gui.sh    # Windows 11-like experience
```

## 📁 Project Structure

```
Ubuntu_24.04_fine_tuning/
├── setup.sh                    # Master setup script
├── README.md                    # This file
├── RECOVERY_INFO.md             # Recovery procedures
├── setup.log                    # Setup execution log
├── networking/                  # Network drivers and configuration
│   ├── setup_drivers.sh
│   ├── setup_drivers_optimized.sh
│   ├── rtl8125_speed_fix.sh
│   └── README.md
├── security/                    # Security hardening scripts
│   ├── setup_security.sh
│   └── README.md
├── authentication/              # Biometric authentication
│   ├── setup_howdy.sh
│   ├── howdy_manage.sh
│   ├── howdy_rollback.sh
│   └── README.md
├── gpu/                         # GPU drivers and compute stack
│   ├── setup_gpu_stack.sh
│   ├── gpu_monitor.sh
│   ├── reenable_rx6800.sh
│   └── README.md
├── virtualization/              # KVM/QEMU and VM management
│   ├── setup_virtualization.sh
│   ├── start-vm.sh
│   ├── stop-vm.sh
│   └── README.md
├── docker/                      # Docker setup and management
│   ├── setup_docker.sh
│   ├── docker_manage.sh
│   ├── docker_volume_backup.sh
│   └── README.md
├── performance/                 # System performance tuning
│   ├── setup_performance.sh
│   └── README.md
├── development/                 # Developer tools and QoL
│   ├── setup_development.sh
│   ├── shell_recovery.sh
│   └── README.md
├── backup/                      # Backup and recovery systems
│   ├── setup_backup.sh
│   ├── system_backup.sh
│   └── README.md
├── gui-customization/           # GUI customization scripts
│   ├── setup_windows_like_gui.sh
│   ├── install_gnome_extensions.sh
│   └── README.md
├── GRUB/                        # GRUB configuration scripts
│   ├── complete_setup.sh
│   ├── backup_grub.sh
│   └── README.md
├── docker-projects/             # Docker example projects
│   └── web-stack/
└── scripts/                     # Legacy scripts (deprecated)
    └── (old numbered scripts for reference)
```
│   ├── 07_developer_qol.sh
│   ├── 08_backup_resilience.sh
│   ├── gpu_monitor.sh
│   ├── docker_manage.sh
│   ├── dev_env.sh
│   ├── system_backup.sh
│   ├── start-vm.sh
│   └── stop-vm.sh
├── docker-projects/
│   └── web-stack/
│       ├── docker-compose.yml
│       └── nginx.conf
└── .vscode/
    ├── settings.json
    └── extensions.json
```

## 🔧 System Requirements

- **OS**: Ubuntu 24.04.3 LTS
- **Hardware**: AMD system with RX 6800 GPU (Vega iGPU + discrete)
- **RAM**: 16GB+ recommended for VM passthrough
- **Storage**: 50GB+ free space
- **Network**: Internet connectivity for package downloads

## ⚠️ Important Notes

### Before Running
1. **Backup your system** - This makes significant changes
2. **Review scripts** - Understand what each phase does
3. **Check hardware compatibility** - Especially for GPU passthrough

### After Setup
1. **Reboot required** - Many changes need a restart
2. **GPU PCI IDs** - Update VFIO configuration with your actual GPU IDs
3. **GitHub authentication** - Run `gh auth login`
4. **First backup** - Create initial system backup

### GPU Passthrough Notes
- Find your GPU PCI IDs: `lspci -nn | grep -E "(VGA|Audio).*AMD"`
- Update `/etc/modprobe.d/vfio.conf` with correct IDs
- BIOS settings: Enable VT-x/AMD-V and IOMMU
- Test in safe environment first

## 🐛 Troubleshooting

### Common Issues

**Script Permission Denied**
```bash
chmod +x setup.sh
chmod +x scripts/*.sh
```

**Package Installation Fails**
```bash
sudo apt update
sudo apt upgrade
```

**GPU Driver Issues**
```bash
# Check driver status
lsmod | grep amdgpu
sudo dmesg | grep amdgpu

# Reinstall if needed
sudo apt install --reinstall mesa-vulkan-drivers
```

**Docker Group Issues**
```bash
# Add user to docker group
sudo usermod -aG docker $USER
# Log out and back in
```

### Logs and Diagnostics

- **Setup log**: `setup.log`
- **System journal**: `journalctl -xe`
- **Package logs**: `/var/log/apt/`
- **Docker logs**: `docker logs <container>`

## 🤝 Contributing

1. Test scripts on clean Ubuntu 24.04.3 installation
2. Follow existing script structure and logging
3. Update documentation for any changes
4. Add error handling and validation

## 📄 License

This project is provided as-is for educational and personal use.

## 🆘 Support

For issues:
1. Check `setup.log` for error details
2. Review individual script outputs
3. Consult `RECOVERY_INFO.md` for recovery procedures
4. Test individual phases to isolate problems

---

**Happy Ubuntu optimizing! 🚀**
