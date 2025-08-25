#!/bin/bash

# Ubuntu 24.04.3 Virtualization & GPU Passthrough Setup
# Implements KVM, QEMU, and GPU passthrough configuration

set -e

echo "=== 5. Virtualization & GPU Passthrough Setup ==="

# Check if virtualization is supported
echo "Checking virtualization support..."
if grep -E "(vmx|svm)" /proc/cpuinfo > /dev/null; then
    echo "✓ CPU virtualization support detected"
else
    echo "✗ CPU virtualization support not detected"
    echo "Please enable VT-x/AMD-V in BIOS"
fi

# Check IOMMU support
echo "Checking IOMMU support..."
if dmesg | grep -E "(DMAR|AMD-Vi)" > /dev/null; then
    echo "✓ IOMMU support detected"
else
    echo "⚠ IOMMU may not be enabled. Check BIOS settings"
fi

# Install KVM and virtualization packages
echo "Installing KVM and virtualization packages..."
sudo apt update
sudo apt install -y \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    bridge-utils \
    virt-manager \
    ovmf \
    virt-viewer \
    gir1.2-spiceclientgtk-3.0 \
    qemu-utils

# Add user to libvirt groups
echo "Adding user to virtualization groups..."
sudo usermod -a -G libvirt,kvm $USER

# Enable and start libvirt services
echo "Enabling libvirt services..."
sudo systemctl enable libvirtd
sudo systemctl start libvirtd

# Configure GRUB for IOMMU and GPU passthrough
echo "Configuring GRUB for GPU passthrough..."

# Backup GRUB configuration
sudo cp /etc/default/grub /etc/default/grub.backup

# Check if already configured
if grep -q "iommu=on" /etc/default/grub; then
    echo "GRUB already configured for IOMMU"
else
    # Add IOMMU and other parameters for AMD systems
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& amd_iommu=on iommu=pt rd.driver.pre=vfio-pci kvm.ignore_msrs=1/' /etc/default/grub
    
    echo "Updated GRUB configuration. Running update-grub..."
    sudo update-grub
fi

# Configure VFIO for GPU passthrough
echo "Configuring VFIO modules..."

# Create VFIO modules configuration
sudo tee /etc/modules-load.d/vfio.conf > /dev/null << 'EOF'
vfio
vfio_iommu_type1
vfio_pci
EOF

# Create VFIO configuration for early loading
sudo tee /etc/modprobe.d/vfio.conf > /dev/null << 'EOF'
# VFIO GPU passthrough configuration
options vfio-pci ids=1002:73df,1002:ab28
softdep amdgpu pre: vfio-pci
softdep snd_hda_intel pre: vfio-pci
EOF

# Note: You'll need to find the actual PCI IDs for your RX 6800
echo "⚠ Important: Update /etc/modprobe.d/vfio.conf with your actual GPU PCI IDs"
echo "Run 'lspci -nn | grep -E \"(VGA|Audio).*AMD\"' to find the correct IDs"

# VM management scripts are available in this directory:
# - start-vm.sh - Start Windows VM with GPU passthrough
# - stop-vm.sh - Stop VM and return GPU to host

# Configure libvirt network
echo "Configuring libvirt default network..."
sudo virsh net-autostart default
sudo virsh net-start default 2>/dev/null || echo "Default network already started"

# Check virtualization status
echo "=== Virtualization Status ==="
echo "KVM modules:"
lsmod | grep kvm

echo ""
echo "Libvirt status:"
sudo systemctl status libvirtd --no-pager -l | head -10

echo ""
echo "Libvirt networks:"
sudo virsh net-list --all

echo ""
echo "IOMMU groups (for GPU passthrough):"
find /sys/kernel/iommu_groups/ -name "devices" -exec bash -c 'echo "IOMMU Group ${1##*/}:"; for dev in $(ls $1); do echo -e "\t$(lspci -nns $dev)"; done' _ {} \; 2>/dev/null | head -20 || echo "IOMMU information not available"

echo "=== Virtualization & GPU Passthrough Setup Complete ==="
echo "Next steps:"
echo "1. Reboot the system to apply GRUB and VFIO changes"
echo "2. Find your GPU PCI IDs: lspci -nn | grep -E \"(VGA|Audio).*AMD\""
echo "3. Update /etc/modprobe.d/vfio.conf with correct PCI IDs"
echo "4. Use virt-manager to create a Windows VM"
echo "5. Configure GPU passthrough in the VM settings"
