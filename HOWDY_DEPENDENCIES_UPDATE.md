# Setup Howdy Script - Dependencies Update

## Problem Identified
The `setup_howdy.sh` script was missing critical dependencies required for Howdy facial recognition, specifically:
- **dlib** - Core facial recognition library
- **face_recognition** - High-level face recognition wrapper
- Additional system and Python dependencies for compilation

## Dependencies Added

### System Dependencies
```bash
# Build tools and libraries
cmake make build-essential ninja-build meson pkg-config
libboost-all-dev libgtk-3-dev libboost-python-dev
libblas-dev liblapack-dev libx11-dev libglib2.0-dev
libpam0g-dev libinih-dev libevdev-dev
libatlas-base-dev gfortran

# Existing dependencies (enhanced)
python3-pip python3-dev python3-setuptools python3-wheel
libpam-python libopencv-dev python3-opencv
v4l-utils fswebcam
```

### Python Dependencies
```bash
# Core packages (in order)
pip setuptools wheel numpy

# Computer vision and facial recognition
dlib                    # Core facial recognition (requires compilation)
face_recognition        # High-level wrapper for dlib
opencv-python          # Computer vision library
imutils scipy pillow   # Supporting libraries
configparser click     # Configuration and CLI tools
```

## Script Enhancements

### 1. System Requirements Check
- **OS Version Check**: Validates Ubuntu 24.04 compatibility
- **Disk Space Check**: Ensures 2GB+ free space for dlib compilation
- **Virtual Machine Detection**: Warns about potential camera issues in VMs

### 2. Enhanced Installation Process
- **Progressive Installation**: System packages → Python core → dlib → face_recognition
- **Compilation Progress**: Visual feedback during long dlib compilation
- **Error Handling**: Proper error detection and user guidance
- **Dependency Verification**: Post-installation validation

### 3. Better User Experience
- **Clear Progress Indicators**: Shows what's happening during long operations
- **Time Estimates**: Warns about 5-15 minute dlib compilation time
- **Interactive Prompts**: Allows user to cancel if requirements not met
- **Detailed Feedback**: Explains what each step accomplishes

## Files Updated

### Modified Files
- **setup_howdy.sh** - Enhanced with complete dependency management
  - Added `check_system_requirements()`
  - Enhanced `install_howdy()` with full dependency chain
  - Added `verify_dependencies()` for post-installation validation
  - Improved error handling and user feedback

### New Files Created
- **test_dependencies.sh** - Standalone dependency testing script
  - Tests Python package installation without Howdy
  - Validates compilation environment
  - Provides isolated testing capability

## Installation Time Expectations

| Component | Estimated Time | Description |
|-----------|---------------|-------------|
| System packages | 2-5 minutes | APT package installation |
| Python basics | 1-2 minutes | pip, setuptools, wheel, numpy |
| **dlib compilation** | **5-15 minutes** | **C++ compilation (CPU intensive)** |
| face_recognition | 1-2 minutes | Python package installation |
| Howdy setup | 2-3 minutes | Configuration and face model |
| **Total** | **11-27 minutes** | **Varies by system performance** |

## Usage Instructions

### Full Installation
```bash
./setup_howdy.sh
```
- Installs all dependencies and configures Howdy
- Includes camera selection integration
- Sets up facial recognition models

### Test Dependencies Only
```bash
./test_dependencies.sh
```
- Tests dependency installation without Howdy
- Useful for validating compilation environment
- Faster testing cycle

### Verify Installation
```bash
python3 -c "import dlib, face_recognition; print('✓ All dependencies working')"
```

## System Requirements

### Minimum Requirements
- Ubuntu 24.04 (or compatible)
- 2GB free disk space (temporary, for compilation)
- Working camera (USB webcam or built-in)
- Internet connection for package downloads

### Recommended
- 4GB+ RAM (for faster compilation)
- IR camera (better security than RGB)
- SSD storage (faster compilation)

## Troubleshooting

### Common Issues
1. **dlib compilation fails**: Usually insufficient memory or missing build tools
2. **Long compilation time**: Normal - dlib builds optimized binaries
3. **No camera detected**: Check camera permissions and v4l2 compatibility
4. **Virtual machine issues**: Cameras may not work properly in VMs

### Quick Fixes
```bash
# If compilation fails, ensure build tools:
sudo apt install -y build-essential cmake libboost-all-dev

# Check camera access:
ls -la /dev/video*
v4l2-ctl --list-devices

# Verify Python environment:
python3 -c "import numpy, cv2; print('Basic deps OK')"
```

The updated script now provides a complete, robust installation process for Howdy with all required dependencies properly managed.
