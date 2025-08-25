#!/bin/bash

# Ubuntu 24.04.3 Networking & Drivers Setup - OPTIMIZED VERSION
# Focus on kernel 6.14 built-in r8169 driver optimization for RTL8125
# August 2025 - Official sources only, Secure Boot compatible

set -e

echo "=== Networking & Drivers Setup - OPTIMIZED VERSION ==="

# Check Secure Boot status
echo "Checking Secure Boot status..."
SECURE_BOOT_STATUS=$(mokutil --sb-state 2>/dev/null || echo "Unknown")
echo "Secure Boot: $SECURE_BOOT_STATUS"

# Check current driver and hardware
echo "Current ethernet controller:"
lspci | grep -E "Ethernet.*Realtek"

echo "Current kernel version:"
uname -r

echo "Current loaded modules:"
lsmod | grep r81 || echo "No r81xx modules loaded"

# Install necessary packages
echo "Installing network optimization tools..."
sudo apt update
sudo apt install -y ethtool linux-tools-common linux-tools-generic

# Check if RTL8125 is already working with r8169
ETHERNET_INTERFACE=$(ip link show | grep -E "enp.*:" | cut -d: -f2 | tr -d ' ' | head -1)

if [ -n "$ETHERNET_INTERFACE" ]; then
    echo "Found ethernet interface: $ETHERNET_INTERFACE"
    
    # Check if it's RTL8125
    if sudo dmesg | grep -q "RTL8125"; then
        echo "✅ RTL8125 detected and working with built-in r8169 driver"
        echo "This is the recommended configuration for Secure Boot systems"
    fi
    
    # Bring interface up
    sudo ip link set "$ETHERNET_INTERFACE" up
    sleep 3
    
    echo "Current interface capabilities:"
    sudo ethtool "$ETHERNET_INTERFACE" | grep -E "(Supported link modes|Speed|Duplex|Link detected)"
    
    # Check if 2.5GbE is supported
    if sudo ethtool "$ETHERNET_INTERFACE" | grep -q "2500baseT"; then
        echo "✅ 2.5GbE capability detected"
        
        # Check link partner capabilities
        echo "Link partner (router/switch) capabilities:"
        sudo ethtool "$ETHERNET_INTERFACE" | grep -A5 "Link partner advertised"
        
        if sudo ethtool "$ETHERNET_INTERFACE" | grep "Link partner" | grep -q "2500baseT"; then
            echo "✅ Link partner supports 2.5GbE - attempting negotiation"
            sudo ethtool -s "$ETHERNET_INTERFACE" speed 2500 duplex full autoneg on
            sleep 5
        else
            echo "⚠️  Link partner does NOT support 2.5GbE"
            echo "Current connection will be limited by router/switch capabilities"
        fi
    else
        echo "⚠️  2.5GbE not detected in interface capabilities"
    fi
    
    # Final status check
    echo "Final connection status:"
    sudo ethtool "$ETHERNET_INTERFACE" | grep -E "(Speed|Duplex|Link detected)"
    
    # Optimize performance settings
    echo "Applying performance optimizations..."
    
    # Enable hardware offloading features that are safe
    sudo ethtool -K "$ETHERNET_INTERFACE" rx on tx on tso on gso on gro on || echo "Some offload features not available"
    
    # Optimize ring buffer sizes if supported
    sudo ethtool -G "$ETHERNET_INTERFACE" rx 4096 tx 4096 2>/dev/null || echo "Ring buffer optimization not supported"
    
    # Set interrupt coalescing for better throughput
    sudo ethtool -C "$ETHERNET_INTERFACE" adaptive-rx on adaptive-tx on 2>/dev/null || echo "Adaptive coalescing not supported"
    
else
    echo "❌ No ethernet interface found"
    echo "Checking for potential issues..."
    
    # Check if any r8125 DKMS modules are conflicting
    if dkms status | grep -q r8125; then
        echo "Found conflicting r8125 DKMS module, removing..."
        sudo dkms remove r8125 --all 2>/dev/null || true
        sudo apt remove -y r8125-dkms 2>/dev/null || true
    fi
    
    # Try to load r8169 manually
    echo "Attempting to load r8169 driver..."
    sudo modprobe r8169
    sleep 3
    
    # Check again
    ETHERNET_INTERFACE=$(ip link show | grep -E "enp.*:" | cut -d: -f2 | tr -d ' ' | head -1)
    if [ -n "$ETHERNET_INTERFACE" ]; then
        echo "✅ Interface detected after manual driver load: $ETHERNET_INTERFACE"
    else
        echo "❌ Interface still not detected - hardware issue possible"
    fi
fi

# Configure systemd-resolved for DNS caching
echo "Configuring systemd-resolved for optimal DNS performance..."
sudo systemctl enable systemd-resolved
sudo systemctl start systemd-resolved

# Create NetworkManager configuration for DNS
sudo tee /etc/NetworkManager/conf.d/dns.conf > /dev/null << 'EOF'
[main]
dns=systemd-resolved

[connection]
# Optimize for wired connections
ipv6.method=auto
ipv4.method=auto
EOF

echo "Restarting NetworkManager..."
sudo systemctl restart NetworkManager

# Test connectivity and speed
if [ -n "$ETHERNET_INTERFACE" ] && ip link show "$ETHERNET_INTERFACE" | grep -q "UP"; then
    echo "Testing connectivity..."
    if ping -c 3 8.8.8.8 >/dev/null 2>&1; then
        echo "✅ Internet connectivity confirmed"
        
        # Basic speed test using wget
        echo "Testing download speed (downloading 10MB test file)..."
        SPEED_TEST=$(wget -O /dev/null -T 10 --quiet --show-progress \
                    "http://speedtest.ftp.otenet.gr/files/test10Mb.db" 2>&1 | \
                    grep -o '[0-9.]*[KMG]B/s' | tail -1 || echo "Speed test failed")
        echo "Download speed: $SPEED_TEST"
    else
        echo "⚠️  No internet connectivity"
    fi
fi

echo ""
echo "=== SETUP COMPLETE ==="
echo ""
echo "🔍 ANALYSIS:"
echo "- Kernel: $(uname -r) with built-in r8169 driver"
echo "- Secure Boot: $SECURE_BOOT_STATUS"
echo "- Interface: ${ETHERNET_INTERFACE:-None detected}"
if [ -n "$ETHERNET_INTERFACE" ]; then
    CURRENT_SPEED=$(ethtool "$ETHERNET_INTERFACE" 2>/dev/null | grep Speed | awk '{print $2}' || echo "Unknown")
    echo "- Current Speed: $CURRENT_SPEED"
fi
echo ""
echo "📋 NOTES:"
echo "- Ubuntu 24.04 kernel 6.14 has excellent built-in RTL8125 support"
echo "- Official Ubuntu r8125-dkms (v9.011.00) conflicts with Secure Boot"
echo "- Built-in r8169 driver provides stable RTL8125 support"
echo "- 2.5GbE speed requires compatible router/switch"
echo ""
echo "🛠️  TROUBLESHOOTING:"
echo "- To check interface: ip link show"
echo "- To check speed: sudo ethtool enp13s0"
echo "- To reset connection: sudo ip link set enp13s0 down && sudo ip link set enp13s0 up"
echo "- Driver info: modinfo r8169"
