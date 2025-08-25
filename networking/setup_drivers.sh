#!/bin/bash

# Ubuntu 24.04.3 Networking & Drivers Setup
# Implements Realtek RTL8125 2.5GbE driver with Secure Boot compatibility
# Updated: August 2025 - Includes fallback strategy and troubleshooting

set -e

echo "=== 1. Networking & Drivers Setup ==="

# Check Secure Boot status
echo "Checking Secure Boot status..."
SECURE_BOOT_STATUS=$(mokutil --sb-state 2>/dev/null || echo "Unknown")
echo "Secure Boot: $SECURE_BOOT_STATUS"

# Check current driver
echo "Current ethernet controller:"
lspci | grep -E "Ethernet.*Realtek"

echo "Current loaded modules:"
lsmod | grep r81 || echo "No r81xx modules loaded"

# Install necessary packages
echo "Installing network tools and dependencies..."
sudo apt update
sudo apt install -y ethtool dkms build-essential linux-headers-$(uname -r)

# Backup existing r8169 driver if present
if [ -f "/lib/modules/$(uname -r)/kernel/drivers/net/ethernet/realtek/r8169.ko.zst" ]; then
    echo "Backing up existing r8169 driver..."
    sudo cp "/lib/modules/$(uname -r)/kernel/drivers/net/ethernet/realtek/r8169.ko.zst" \
           "/lib/modules/$(uname -r)/kernel/drivers/net/ethernet/realtek/r8169.zst.bak"
fi

# Strategy 1: Try official Ubuntu r8125-dkms package (Secure Boot compatible)
echo "Attempting to install official Ubuntu r8125-dkms package..."
if sudo apt install -y r8125-dkms 2>/dev/null; then
    echo "Official r8125-dkms package installed successfully"
    
    # Check if module can be loaded with Secure Boot
    if sudo modprobe r8125 2>/dev/null; then
        echo "r8125 module loaded successfully"
    else
        echo "WARNING: r8125 module cannot be loaded (likely due to Secure Boot)"
        echo "Falling back to built-in r8169 driver..."
        
        # Restore r8169 if backed up
        if [ -f "/lib/modules/$(uname -r)/kernel/drivers/net/ethernet/realtek/r8169.zst.bak" ]; then
            sudo mv "/lib/modules/$(uname -r)/kernel/drivers/net/ethernet/realtek/r8169.zst.bak" \
                   "/lib/modules/$(uname -r)/kernel/drivers/net/ethernet/realtek/r8169.ko.zst"
            sudo depmod -a
            sudo modprobe r8169
        fi
    fi
else
    echo "Failed to install official r8125-dkms package"
    
    # Strategy 2: Use built-in r8169 driver
    echo "Using built-in r8169 driver for RTL8125 support..."
    if [ -f "/lib/modules/$(uname -r)/kernel/drivers/net/ethernet/realtek/r8169.zst.bak" ]; then
        sudo mv "/lib/modules/$(uname -r)/kernel/drivers/net/ethernet/realtek/r8169.zst.bak" \
               "/lib/modules/$(uname -r)/kernel/drivers/net/ethernet/realtek/r8169.ko.zst"
        sudo depmod -a
        sudo modprobe r8169
    fi
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

# Check ethernet status and speed optimization
echo "Checking ethernet interface..."
ETHERNET_INTERFACE=$(ip link show | grep -E "enp.*:" | cut -d: -f2 | tr -d ' ' | head -1)
if [ -n "$ETHERNET_INTERFACE" ]; then
    echo "Ethernet interface: $ETHERNET_INTERFACE"
    
    # Bring interface up if down
    sudo ip link set "$ETHERNET_INTERFACE" up
    
    # Wait for link to establish
    sleep 3
    
    # Check current speed and capabilities
    echo "Current interface status:"
    sudo ethtool "$ETHERNET_INTERFACE" | grep -E "(Speed|Duplex|Link detected)" || echo "Interface may be down"
    
    # Try to negotiate 2.5Gbps if supported
    echo "Checking 2.5Gbps support..."
    if sudo ethtool "$ETHERNET_INTERFACE" | grep -q "2500baseT"; then
        echo "2.5Gbps supported, attempting to set speed..."
        sudo ethtool -s "$ETHERNET_INTERFACE" speed 2500 duplex full autoneg on || \
        echo "Failed to set 2.5Gbps, using auto-negotiation"
    else
        echo "2.5Gbps not detected in capabilities, using auto-negotiation"
    fi
    
    # Final speed check
    echo "Final interface speed:"
    sudo ethtool "$ETHERNET_INTERFACE" | grep -E "(Speed|Duplex|Link detected)"
else
    echo "No ethernet interface found"
fi

echo "=== Networking & Drivers Setup Complete ==="
echo ""
echo "TROUBLESHOOTING NOTES:"
echo "- If stuck at 60% during installation: sudo pkill apt && sudo dpkg --configure -a"
echo "- If Secure Boot prevents r8125 loading: built-in r8169 driver is used instead"
echo "- For 2.5Gbps: ensure cable and switch/router support 2.5GbE"
echo "- Current driver status: $(lsmod | grep -E 'r816|r812' | awk '{print $1}' || echo 'none loaded')"
echo ""
echo "Note: Reboot may be required for driver changes to take effect"
