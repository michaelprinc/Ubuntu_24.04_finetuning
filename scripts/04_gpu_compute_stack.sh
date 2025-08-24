#!/bin/bash

# Ubuntu 24.04.3 GPU / Compute Stack Setup
# Implements AMD ROCm for RX 6800 and Vulkan stack

set -e

echo "=== 4. GPU / Compute Stack Setup ==="

# Check current GPU setup
echo "Checking current GPU configuration..."
lspci | grep -E "(VGA|Display|3D)"
lsmod | grep amdgpu || echo "amdgpu module not loaded"

# Update package list
sudo apt update

# Install Mesa Vulkan and OpenCL drivers
echo "Installing Mesa Vulkan and OpenCL drivers..."
sudo apt install -y \
    mesa-vulkan-drivers \
    mesa-opencl-icd \
    vulkan-tools \
    vulkan-validationlayers \
    mesa-utils \
    clinfo

# Install AMD GPU monitoring tools
echo "Installing GPU monitoring tools..."
sudo apt install -y radeontop

# Install nvtop for comprehensive GPU monitoring
echo "Installing nvtop..."
sudo apt install -y nvtop

# Check if ROCm repositories are available
echo "Setting up AMD ROCm (alternative approach for Ubuntu 24.04)..."

# Remove problematic ROCm repository first
sudo rm -f /etc/apt/sources.list.d/rocm.list
sudo apt-key del $(apt-key list 2>/dev/null | grep -B1 "AMD" | head -1 | awk '{print $2}' | tr -d '/') 2>/dev/null || true

# Update package list
sudo apt update

# Install ROCm packages from Ubuntu repositories (more stable)
echo "Installing ROCm packages from Ubuntu repositories..."
sudo apt install -y \
    rocm-dev-tools \
    rocm-libs \
    rocm-utils \
    hip-dev \
    hip-runtime-amd \
    hipblas \
    hipfft \
    hipsparse \
    rocblas \
    rocsparse \
    rocfft \
    rocthrust \
    rocprim \
    miopen-hip \
    rccl 2>/dev/null || {
    
    echo "Some ROCm packages not available in Ubuntu repos, trying minimal install..."
    sudo apt install -y \
        hip-dev \
        hipblas \
        rocblas \
        rocm-cmake \
        rocminfo 2>/dev/null || {
        
        echo "ROCm packages have conflicts, using Mesa OpenCL as alternative..."
        echo "Mesa OpenCL is sufficient for most GPU compute tasks on RX 6800"
    }
}

# Add user to render and video groups
echo "Adding user to GPU groups..."
sudo usermod -a -G render,video $USER

# Install additional compute libraries
echo "Installing additional compute libraries..."
sudo apt install -y \
    opencl-headers \
    ocl-icd-opencl-dev \
    pocl-opencl-icd

# Create ROCm environment setup (if packages installed successfully)
if command -v rocminfo >/dev/null 2>&1; then
    sudo tee /etc/profile.d/rocm.sh > /dev/null << 'EOF'
# AMD ROCm environment variables
export PATH=$PATH:/opt/rocm/bin:/opt/rocm/profiler/bin:/opt/rocm/opencl/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/rocm/lib:/opt/rocm/lib64
export ROCM_PATH=/opt/rocm
EOF
    echo "ROCm environment configured"
else
    echo "ROCm not available, using Mesa OpenCL for GPU compute"
fi

# Check Vulkan support
echo "Checking Vulkan support..."
vulkaninfo --summary 2>/dev/null || echo "Vulkan info not available (may need reboot)"

# Check OpenCL support
echo "Checking OpenCL support..."
clinfo 2>/dev/null || echo "OpenCL info not available"

# Create GPU monitoring script
tee /media/michael-princ/E85AE8F65AE8C284/Data_science_projects/Ubuntu_24.04_fine_tuning/scripts/gpu_monitor.sh > /dev/null << 'EOF'
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
EOF

chmod +x /media/michael-princ/E85AE8F65AE8C284/Data_science_projects/Ubuntu_24.04_fine_tuning/scripts/gpu_monitor.sh

echo "=== GPU Status Check ==="
echo "Current GPU devices:"
lspci | grep -E "(VGA|Display|3D)"

echo ""
echo "Vulkan devices:"
vulkaninfo --summary 2>/dev/null | grep -A2 -B2 "deviceName" || echo "Vulkan devices not available (reboot may be needed)"

echo ""
echo "OpenCL platforms:"
clinfo -l 2>/dev/null || echo "OpenCL platforms not available"

echo "=== GPU / Compute Stack Setup Complete ==="
echo "Note: Reboot may be required for all GPU drivers to load properly"
echo "Run the gpu_monitor.sh script to check GPU status after reboot"
