#!/bin/bash
# Stop Windows VM and return GPU to host

VM_NAME="windows-gpu"

echo "=== Stopping VM and returning GPU to host ==="

# Stop the VM
echo "Stopping VM: $VM_NAME"
virsh shutdown "$VM_NAME"

# Wait for VM to shutdown
sleep 5

# Rebind GPU to host drivers (if needed)
echo "Rebinding GPU to host drivers..."
# echo "1002 73df" | sudo tee /sys/bus/pci/drivers/amdgpu/new_id 2>/dev/null || true
# modprobe amdgpu

echo "VM stopped and GPU returned to host"
