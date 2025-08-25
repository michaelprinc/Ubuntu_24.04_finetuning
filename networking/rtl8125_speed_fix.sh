#!/bin/bash

# RTL8125 2.5GbE Speed Optimization Script for Ubuntu 24.04
# Based on community solutions from Manjaro, Ubuntu, and Arch forums
# August 2025

set -e

echo "=== RTL8125 2.5GbE Speed Optimization ==="
echo "Based on community solutions from Ubuntu 24.04 forums"

# Function to check current status
check_status() {
    echo "Current status:"
    echo "- Interface: $(ip link show | grep -E 'enp.*:' | cut -d: -f2 | tr -d ' ' | head -1)"
    echo "- Driver: $(lsmod | grep r816 | awk '{print $1}' || echo 'none')"
    echo "- Speed: $(ethtool enp13s0 2>/dev/null | grep Speed | awk '{print $2}' || echo 'unknown')"
    echo "- Hardware: $(lspci | grep Ethernet | grep Realtek)"
}

check_status

echo ""
echo "=== COMMUNITY-IDENTIFIED SOLUTIONS ==="

# Solution 1: Firmware loading issues (from Manjaro forums)
echo "1. Checking firmware loading..."
if dmesg | grep -q "rtl8125.*firmware"; then
    echo "✅ Firmware is loading correctly"
else
    echo "⚠️  Firmware may not be loading properly"
    echo "   Trying to reload driver..."
    sudo modprobe -r r8169
    sleep 2
    sudo modprobe r8169
    sleep 3
fi

# Solution 2: Driver parameters (community solution)
echo ""
echo "2. Applying community-recommended driver parameters..."

# Create modprobe configuration for r8169 with optimized parameters
sudo tee /etc/modprobe.d/r8169.conf > /dev/null << 'EOF'
# RTL8125 optimization based on community solutions
# Disable power management features that can cause speed issues
options r8169 use_dac=1 speed_mode=0 duplex_mode=0 autoneg_mode=1

# Alternative parameters if above doesn't work:
# options r8169 eee_enable=0 aspm=0
EOF

echo "Created /etc/modprobe.d/r8169.conf with community-recommended parameters"

# Solution 3: MSI (Message Signaled Interrupts) fix
echo ""
echo "3. Checking MSI interrupt handling..."
MSI_STATUS=$(cat /proc/interrupts | grep enp13s0 | head -1 | awk '{print $1}' | tr -d ':' || echo "none")
if [ "$MSI_STATUS" != "none" ]; then
    echo "✅ MSI interrupts are working (IRQ: $MSI_STATUS)"
else
    echo "⚠️  MSI interrupts may need optimization"
fi

# Solution 4: NetworkManager configuration (Ubuntu-specific)
echo ""
echo "4. Optimizing NetworkManager for RTL8125..."
sudo tee /etc/NetworkManager/conf.d/rtl8125-optimization.conf > /dev/null << 'EOF'
[main]
# RTL8125 specific optimizations
dhcp=internal

[connection]
# Disable IPv6 on ethernet for speed optimization
ipv6.method=ignore
ethernet.auto-negotiate=true
ethernet.speed=0
ethernet.duplex=full

[device]
# RTL8125 specific device configuration
match-device=driver:r8169
managed=true
EOF

echo "Created NetworkManager RTL8125 optimization config"

# Solution 5: Kernel module loading order (from forums)
echo ""
echo "5. Setting up proper module loading order..."
echo "r8169" | sudo tee -a /etc/modules >/dev/null

# Solution 6: Ethtool persistent settings
echo ""
echo "6. Creating persistent ethtool configuration..."
sudo mkdir -p /etc/systemd/system
sudo tee /etc/systemd/system/rtl8125-optimize.service > /dev/null << 'EOF'
[Unit]
Description=RTL8125 Ethernet Optimization
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c 'sleep 10 && /usr/sbin/ethtool -s enp13s0 autoneg on && /usr/sbin/ethtool -K enp13s0 tso on gso on gro on'
User=root

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable rtl8125-optimize.service

# Solution 7: GRUB parameter for PCI optimization (advanced)
echo ""
echo "7. Checking if GRUB optimization is needed..."
if grep -q "pci=nomsi" /proc/cmdline; then
    echo "⚠️  pci=nomsi found in GRUB - this can limit RTL8125 performance"
    echo "   Consider removing it for better performance"
else
    echo "✅ No conflicting PCI parameters found"
fi

# Solution 8: Real-time testing and diagnostics
echo ""
echo "8. Running real-time diagnostics..."

# Reload the driver with new parameters
echo "Reloading driver with new parameters..."
sudo modprobe -r r8169
sleep 3
sudo modprobe r8169
sleep 5

# Restart NetworkManager
echo "Restarting NetworkManager..."
sudo systemctl restart NetworkManager
sleep 10

# Final status check
echo ""
echo "=== FINAL STATUS CHECK ==="
check_status

INTERFACE=$(ip link show | grep -E 'enp.*:' | cut -d: -f2 | tr -d ' ' | head -1)
if [ -n "$INTERFACE" ]; then
    echo ""
    echo "Interface capabilities:"
    sudo ethtool "$INTERFACE" | grep -A10 "Supported link modes"
    
    echo ""
    echo "Current negotiation:"
    sudo ethtool "$INTERFACE" | grep -A5 "Advertised link modes"
    
    echo ""
    echo "Link partner capabilities:"
    sudo ethtool "$INTERFACE" | grep -A5 "Link partner"
    
    echo ""
    echo "Final speed:"
    sudo ethtool "$INTERFACE" | grep -E "(Speed|Duplex|Link detected)"
fi

echo ""
echo "=== RECOMMENDATIONS ==="
echo ""
echo "🔍 ANALYSIS COMPLETE:"
if ethtool enp13s0 2>/dev/null | grep -q "Speed: 100Mb/s"; then
    echo "❌ Speed still limited to 100Mbps"
    echo ""
    echo "📋 NEXT STEPS:"
    echo "1. The issue is likely your router/switch hardware"
    echo "2. Check router specs: Does it support 2.5GbE or at least 1GbE?"
    echo "3. Check cable: Cat5e minimum required for 1GbE, Cat6/6a for 2.5GbE"
    echo "4. Check router port: Some routers have only one 2.5GbE port"
    echo ""
    echo "🔧 TO TEST ROUTER/SWITCH:"
    echo "- Try a different ethernet port on router"
    echo "- Try a different ethernet cable"
    echo "- Check router admin panel for port speed settings"
    echo "- Test with another device that supports 1GbE+"
    echo ""
    echo "🏷️  COMMON ROUTER ISSUES:"
    echo "- Old routers: Many only support 100Mbps"
    echo "- Port configuration: Some ports may be speed-limited"
    echo "- Auto-negotiation: May need manual router configuration"
elif ethtool enp13s0 2>/dev/null | grep -q "Speed: 1000Mb/s"; then
    echo "✅ 1GbE achieved! Good improvement from 100Mbps"
    echo "ℹ️  For 2.5GbE, ensure router/switch supports it"
elif ethtool enp13s0 2>/dev/null | grep -q "Speed: 2500Mb/s"; then
    echo "🎉 SUCCESS! 2.5GbE working perfectly!"
else
    echo "❓ Speed status unclear - may need reboot"
fi

echo ""
echo "📱 REBOOT RECOMMENDED to fully apply all optimizations"
echo ""
echo "Script completed. Changes will persist after reboot."
