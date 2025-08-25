# GPU Configuration

This folder contains scripts for GPU driver installation, compute stack setup, and monitoring tools.

## Scripts

- **`setup_gpu_stack.sh`** - Install AMD ROCm and Vulkan drivers for RX 6800
- **`gpu_monitor.sh`** - Monitor GPU status and performance
- **`reenable_rx6800.sh`** - Re-enable RX 6800 GPU if disabled

## Usage

```bash
# Install GPU drivers and compute stack
./setup_gpu_stack.sh

# Monitor GPU status
./gpu_monitor.sh

# Re-enable GPU if needed
./reenable_rx6800.sh
```

## Features

- AMD ROCm installation for compute workloads
- Mesa Vulkan drivers
- OpenCL support
- GPU monitoring tools (radeontop, nvtop)
- Mesa utilities for testing

## Requirements

- Ubuntu 24.04.3 LTS
- AMD RX 6800 GPU (or compatible)
- Root/sudo access

## Notes

- Supports both ROCm and Mesa OpenCL
- Includes validation tools
- Performance monitoring capabilities
- Compatible with machine learning frameworks
