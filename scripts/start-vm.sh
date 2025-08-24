#!/bin/bash
# Start Windows VM with GPU passthrough

VM_NAME="windows-gpu"

echo "=== Starting VM with GPU Passthrough ==="

# Check if VM exists
if ! virsh list --all | grep -q "$VM_NAME"; then
    echo "VM '$VM_NAME' not found. Please create it first using virt-manager."
    exit 1
fi

# Unbind GPU from host (if needed)
echo "Unbinding GPU from host drivers..."
# echo "0000:0c:00.0" | sudo tee /sys/bus/pci/devices/0000:0c:00.0/driver/unbind 2>/dev/null || true
# echo "0000:0c:00.1" | sudo tee /sys/bus/pci/devices/0000:0c:00.1/driver/unbind 2>/dev/null || true

# Start the VM
echo "Starting VM: $VM_NAME"
virsh start "$VM_NAME"

echo "VM started. Use virt-viewer to connect:"
echo "virt-viewer $VM_NAME"
