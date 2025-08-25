#!/bin/bash
# GPU Monitoring Script

echo "=== GPU Status ==="
echo "AMD GPU Information:"
lspci | grep -E "(VGA|Display|3D)"

echo ""
echo "GPU Memory Usage:"
if command -v radeontop >/dev/null; then
    timeout 5s radeontop -d - | head -10
fi

echo ""
echo "GPU Processes:"
if command -v nvtop >/dev/null; then
    echo "Use 'nvtop' for interactive GPU monitoring"
fi

echo ""
echo "ROCm Status:"
if command -v rocminfo >/dev/null 2>&1; then
    echo "ROCm installed successfully"
    rocminfo | grep -E "(Agent|Name)" | head -10 || echo "ROCm available but needs configuration"
elif [ -d "/opt/rocm" ]; then
    echo "ROCm directory found: /opt/rocm"
    ls -la /opt/rocm/ | head -10
else
    echo "ROCm not installed - using Mesa OpenCL instead"
    echo "Mesa OpenCL provides good GPU compute support for RX 6800"
fi

echo ""
echo "Vulkan Devices:"
vulkaninfo --summary 2>/dev/null | grep -A5 -B5 "deviceName" || echo "No Vulkan devices found"
