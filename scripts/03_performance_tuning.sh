#!/bin/bash

# Ubuntu 24.04.3 Performance & Hardware Acceleration
# Implements kernel tuning and performance optimizations

set -e

echo "=== 3. Performance & Hardware Acceleration Setup ==="

# Install tuned for performance profiles
echo "Installing tuned for performance management..."
sudo apt update
sudo apt install -y tuned

# Create custom tuned profile for workstation
sudo mkdir -p /etc/tuned/workstation-performance

sudo tee /etc/tuned/workstation-performance/tuned.conf > /dev/null << 'EOF'
[main]
summary=Workstation performance profile with low latency optimizations
include=throughput-performance

[sysctl]
# Memory management
vm.swappiness=10
vm.dirty_ratio=15
vm.dirty_background_ratio=5

# File system optimizations
fs.inotify.max_user_watches=524288
fs.inotify.max_user_instances=256

# Network optimizations
net.core.rmem_default=262144
net.core.rmem_max=16777216
net.core.wmem_default=262144
net.core.wmem_max=16777216

# CPU scheduling
kernel.sched_migration_cost_ns=5000000
kernel.sched_autogroup_enabled=0

[cpu]
governor=performance
energy_perf_bias=performance
min_perf_pct=100
EOF

# Apply the tuned profile
sudo tuned-adm profile workstation-performance

# Backup original sysctl.conf
sudo cp /etc/sysctl.conf /etc/sysctl.conf.backup

# Add additional sysctl optimizations
sudo tee -a /etc/sysctl.conf > /dev/null << 'EOF'

# Performance optimizations added by setup script
vm.swappiness=10
fs.inotify.max_user_watches=524288
fs.inotify.max_user_instances=256

# Network performance
net.core.netdev_max_backlog=5000
net.core.rmem_default=262144
net.core.rmem_max=16777216
net.core.wmem_default=262144
net.core.wmem_max=16777216

# Memory management
vm.dirty_ratio=15
vm.dirty_background_ratio=5
vm.vfs_cache_pressure=50
EOF

# Apply sysctl settings
sudo sysctl -p

# Check if ZSTD compression is enabled (default in 24.04)
echo "Checking package compression settings..."
grep -r "Compression" /etc/apt/apt.conf.d/ || echo "Using default compression settings"

# Install additional performance monitoring tools
echo "Installing performance monitoring tools..."
sudo apt install -y htop btop iotop sysstat

# Enable sysstat for system monitoring
sudo systemctl enable sysstat
sudo systemctl start sysstat

# Check current performance settings
echo "=== Performance Status ==="
echo "Current tuned profile:"
tuned-adm active

echo ""
echo "Current sysctl settings (key values):"
sysctl vm.swappiness fs.inotify.max_user_watches

echo ""
echo "CPU governor:"
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null | head -5 || echo "CPU frequency scaling not available"

echo ""
echo "Memory information:"
free -h

echo "=== Performance & Hardware Acceleration Complete ==="
