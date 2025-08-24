#!/bin/bash

# Ubuntu 24.04.3 Networking & Drivers Setup
# Implements Realtek r8125 driver and NetworkManager DNS caching

set -e

echo "=== 1. Networking & Drivers Setup ==="

# Check current driver
echo "Current ethernet controller:"
lspci | grep -E "Ethernet.*Realtek"

echo "Current loaded modules:"
lsmod | grep r81 || echo "No r81xx modules loaded"

# Install necessary packages
echo "Installing network tools and dependencies..."
sudo apt update
sudo apt install -y ethtool dkms build-essential linux-headers-$(uname -r)

# Check if r8125 driver is already available
if modinfo r8125 >/dev/null 2>&1; then
    echo "r8125 driver is already available"
else
    echo "Installing Realtek r8125 driver..."
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Download and install r8125 driver
    wget https://github.com/awesometic/realtek-r8125-dkms/archive/refs/heads/main.zip
    unzip main.zip
    cd realtek-r8125-dkms-main
    
    # Install via DKMS
    sudo cp -r . /usr/src/r8125-9.012.03
    sudo dkms add -m r8125 -v 9.012.03
    sudo dkms build -m r8125 -v 9.012.03
    sudo dkms install -m r8125 -v 9.012.03
    
    # Clean up
    cd /
    rm -rf "$TEMP_DIR"
fi

# Configure systemd-resolved for DNS caching
echo "Configuring systemd-resolved..."
sudo systemctl enable systemd-resolved
sudo systemctl start systemd-resolved

# Create NetworkManager configuration for DNS
sudo tee /etc/NetworkManager/conf.d/dns.conf > /dev/null << 'EOF'
[main]
dns=systemd-resolved
EOF

echo "Restarting NetworkManager..."
sudo systemctl restart NetworkManager

# Check ethernet status
echo "Checking ethernet interface..."
ETHERNET_INTERFACE=$(ip link show | grep -E "enp.*:" | cut -d: -f2 | tr -d ' ' | head -1)
if [ -n "$ETHERNET_INTERFACE" ]; then
    echo "Ethernet interface: $ETHERNET_INTERFACE"
    sudo ethtool "$ETHERNET_INTERFACE" | grep -E "(Speed|Duplex|Link detected)" || echo "Interface may be down"
else
    echo "No ethernet interface found"
fi

echo "=== Networking & Drivers Setup Complete ==="
echo "Note: Reboot may be required for driver changes to take effect"
