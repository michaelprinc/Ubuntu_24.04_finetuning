#!/bin/bash

# Ubuntu 24.04.3 Howdy (Facial Recognition) Setup
# Enables facial recognition authentication using Howdy
# Compatible with Ubuntu 24.04 and most webcams

set -e

echo "=== Howdy Facial Recognition Authentication Setup ==="

# Function to check webcam
check_webcam() {
    echo "Checking for available webcams..."
    if ls /dev/video* >/dev/null 2>&1; then
        echo "✓ Webcam(s) detected:"
        for cam in /dev/video*; do
            echo "  - $cam"
        done
        return 0
    else
        echo "✗ No webcam detected. Howdy requires a webcam to function."
        echo "Please ensure your webcam is connected and recognized by the system."
        return 1
    fi
}

# Function to select camera interactively
select_camera() {
    echo "Multiple cameras detected. Let's select the right one for Howdy."
    echo ""
    
    # Check if camera was already selected
    if [ -f "/tmp/howdy_selected_camera" ]; then
        local selected=$(cat /tmp/howdy_selected_camera)
        echo "Previously selected camera: $selected"
        read -p "Use this camera? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            echo "$selected"
            return 0
        fi
    fi
    
    # Run camera selection tool
    if [ -f "./select_camera.sh" ]; then
        echo "Starting camera selection tool..."
        if ./select_camera.sh; then
            if [ -f "/tmp/howdy_selected_camera" ]; then
                cat /tmp/howdy_selected_camera
                return 0
            fi
        fi
    else
        echo "Camera selection tool not found. Using first available camera."
        echo "/dev/video0"
        return 0
    fi
    
    echo "/dev/video0"
    return 0
}

# Function to check if IR camera is available
check_ir_camera() {
    echo "Checking for IR camera support..."
    # Check for Windows Hello compatible cameras
    if lsusb | grep -i "intel\|realtek" | grep -i "camera\|webcam" >/dev/null 2>&1; then
        echo "✓ Potential IR camera support detected"
        echo "ℹ  Howdy works best with IR cameras but can work with regular webcams"
    else
        echo "ℹ  Regular webcam detected - Howdy will work but may be less secure"
    fi
}

# Function to check system requirements
check_system_requirements() {
    echo "Checking system requirements..."
    
    # Check Ubuntu version
    if ! grep -q "Ubuntu 24.04" /etc/os-release; then
        echo "⚠ Warning: This script is optimized for Ubuntu 24.04"
        echo "  Current system: $(lsb_release -d | cut -f2)"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Check available disk space (dlib compilation needs space)
    available_space=$(df /tmp | tail -1 | awk '{print $4}')
    if [ "$available_space" -lt 2000000 ]; then # 2GB in KB
        echo "⚠ Warning: Less than 2GB free space available"
        echo "  dlib compilation requires significant temporary space"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Check if running on a virtual machine (cameras may not work well)
    if grep -q "hypervisor\|vmware\|virtualbox\|qemu\|kvm" /proc/cpuinfo 2>/dev/null; then
        echo "⚠ Warning: Virtual machine detected"
        echo "  Facial recognition may not work properly in VMs"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    echo "✓ System requirements check completed"
}

# Function to verify dependencies
verify_dependencies() {
    echo "Verifying installed dependencies..."
    local failed=0
    
    # Check system packages
    local system_deps=("cmake" "build-essential" "python3-dev" "libopencv-dev" "v4l-utils" "fswebcam")
    for dep in "${system_deps[@]}"; do
        if dpkg -l | grep -q "^ii.*$dep"; then
            echo "✓ $dep - installed"
        else
            echo "✗ $dep - missing"
            failed=1
        fi
    done
    
    # Check Python packages
    echo "Checking Python packages..."
    local python_deps=("numpy" "opencv-python" "dlib" "face_recognition")
    for dep in "${python_deps[@]}"; do
        if python3 -c "import $dep" 2>/dev/null; then
            local version=$(python3 -c "import $dep; print(getattr($dep, '__version__', 'unknown'))" 2>/dev/null)
            echo "✓ $dep - $version"
        else
            echo "✗ $dep - missing or broken"
            failed=1
        fi
    done
    
    if [ $failed -eq 1 ]; then
        echo ""
        echo "⚠ Some dependencies are missing or broken"
        echo "The installation may not complete successfully"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        echo "✓ All dependencies verified successfully"
    fi
}

# Function to install Howdy
install_howdy() {
    echo "Installing Howdy and dependencies..."
    
    # Update package list
    sudo apt update
    
    # Install system dependencies first
    echo "Installing system dependencies..."
    sudo apt install -y \
        python3-pip \
        python3-dev \
        python3-setuptools \
        python3-wheel \
        libpam-python \
        cmake \
        make \
        build-essential \
        libopencv-dev \
        python3-opencv \
        v4l-utils \
        fswebcam \
        libboost-all-dev \
        libgtk-3-dev \
        libboost-python-dev \
        libblas-dev \
        liblapack-dev \
        libx11-dev \
        libglib2.0-dev \
        libpam0g-dev \
        libinih-dev \
        libevdev-dev \
        ninja-build \
        meson \
        pkg-config \
        libatlas-base-dev \
        gfortran
    
    # Install Python dependencies via pip
    echo "Installing Python dependencies..."
    
    # Install core dependencies
    pip3 install --user --upgrade pip setuptools wheel
    
    # Install numpy first (required for dlib compilation)
    pip3 install --user numpy
    
    # Install dlib (this can take several minutes to compile)
    echo "Installing dlib (this may take 5-15 minutes to compile)..."
    echo "Note: The build may appear to hang at 100% - please be patient!"
    echo "Progress indicators:"
    echo "  1. Downloading source..."
    echo "  2. Setting up build environment..."
    echo "  3. Compiling (this is the slow part)..."
    echo "  4. Installing..."
    echo ""
    
    # Show a progress indicator during dlib installation
    (
        pip3 install --user dlib --verbose 2>&1 | while read line; do
            if echo "$line" | grep -q "Downloading\|Collecting"; then
                echo "  → Step 1: $line"
            elif echo "$line" | grep -q "Building\|Preparing"; then
                echo "  → Step 2: $line"
            elif echo "$line" | grep -q "Running.*build_ext\|cmake\|make"; then
                echo "  → Step 3: Compiling... (please wait)"
            elif echo "$line" | grep -q "Successfully\|installed"; then
                echo "  → Step 4: $line"
            fi
        done
    ) || {
        echo "✗ Failed to install dlib"
        echo "This is often due to insufficient memory or missing development tools"
        echo "Try running: sudo apt install -y build-essential cmake libboost-all-dev"
        return 1
    }
    
    # Install face recognition library
    echo "Installing face_recognition library..."
    pip3 install --user face_recognition
    
    # Install additional Python packages that Howdy might need
    pip3 install --user \
        opencv-python \
        imutils \
        scipy \
        pillow \
        configparser \
        click
    
    # Add Howdy PPA (if available) or install from GitHub
    echo "Adding Howdy repository..."
    
    # Try PPA first
    if sudo add-apt-repository ppa:boltgolt/howdy -y 2>/dev/null; then
        sudo apt update
        sudo apt install -y howdy
        echo "✓ Howdy installed from PPA"
    else
        echo "PPA not available, installing from GitHub..."
        install_howdy_from_github
    fi
}

# Function to install Howdy from GitHub
install_howdy_from_github() {
    echo "Installing Howdy from GitHub source..."
    
    # Install git if not present
    sudo apt install -y git
    
    # Verify Python dependencies are installed
    echo "Verifying Python dependencies..."
    python3 -c "import dlib, face_recognition, cv2, numpy; print('✓ All Python dependencies available')" || {
        echo "✗ Python dependencies missing. Please run the main installation first."
        return 1
    }
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Clone Howdy repository
    echo "Cloning Howdy repository..."
    git clone https://github.com/boltgolt/howdy.git
    cd howdy
    
    # Build and install Howdy using meson
    echo "Building Howdy from source..."
    meson setup build
    meson compile -C build
    
    # Install Howdy
    echo "Installing Howdy..."
    sudo meson install -C build
    
    # Ensure proper permissions
    sudo chmod +x /lib/security/howdy/cli.py
    sudo chown root:root -R /lib/security/howdy/
    
    # Cleanup
    cd ~
    rm -rf "$TEMP_DIR"
    
    echo "✓ Howdy installed from source"
}

# Function to configure Howdy
configure_howdy() {
    echo "Configuring Howdy..."
    
    # Get selected camera
    local selected_camera
    if [ -f "/tmp/howdy_selected_camera" ]; then
        selected_camera=$(cat /tmp/howdy_selected_camera)
        echo "Using selected camera: $selected_camera"
    else
        selected_camera="/dev/video0"
        echo "Using default camera: $selected_camera"
    fi
    
    # Backup original PAM configuration
    sudo cp /etc/pam.d/sudo /etc/pam.d/sudo.howdy-backup
    sudo cp /etc/pam.d/su /etc/pam.d/su.howdy-backup
    
    # Update Howdy configuration with selected camera
    if [ -f "/lib/security/howdy/config.ini" ]; then
        echo "Updating Howdy configuration..."
        
        # Extract device number from path (e.g., /dev/video0 -> 0)
        local device_num=$(echo "$selected_camera" | grep -o '[0-9]*$')
        
        # Update device path in config
        sudo sed -i "s/^device_path = .*/device_path = $selected_camera/" /lib/security/howdy/config.ini
        
        # Update device number if the field exists
        if grep -q "^device_id" /lib/security/howdy/config.ini; then
            sudo sed -i "s/^device_id = .*/device_id = $device_num/" /lib/security/howdy/config.ini
        fi
        
        # Set reasonable defaults for better recognition
        sudo sed -i 's/^certainty = .*/certainty = 3.5/' /lib/security/howdy/config.ini
        sudo sed -i 's/^timeout = .*/timeout = 4/' /lib/security/howdy/config.ini
        sudo sed -i 's/^ignore_closed_lid = .*/ignore_closed_lid = true/' /lib/security/howdy/config.ini
        
        echo "✓ Howdy configuration updated with camera: $selected_camera"
    else
        echo "⚠ Howdy config file not found, will use defaults"
    fi
    
    # Check if Howdy is already configured in PAM
    if ! grep -q "pam_python.so" /etc/pam.d/sudo; then
        echo "Configuring PAM for sudo..."
        # Add Howdy to sudo PAM configuration
        sudo sed -i '1i auth sufficient pam_python.so /lib/security/howdy/pam.py' /etc/pam.d/sudo
    fi
    
    if ! grep -q "pam_python.so" /etc/pam.d/su; then
        echo "Configuring PAM for su..."
        # Add Howdy to su PAM configuration  
        sudo sed -i '1i auth sufficient pam_python.so /lib/security/howdy/pam.py' /etc/pam.d/su
    fi
    
    echo "✓ PAM configuration updated"
}

# Function to add user face model
setup_face_model() {
    echo "Setting up facial recognition model..."
    echo "You will now be prompted to capture your face for authentication."
    echo "Please ensure good lighting and look directly at the camera."
    
    read -p "Press Enter to continue with face capture..."
    
    # Add face model for current user using the correct command path
    sudo python3 /lib/security/howdy/cli.py add $USER
    
    if [ $? -eq 0 ]; then
        echo "✓ Face model added successfully"
        echo "You can add additional models later with: sudo python3 /lib/security/howdy/cli.py add $USER"
    else
        echo "✗ Failed to add face model"
        echo "You can try again later with: sudo python3 /lib/security/howdy/cli.py add $USER"
    fi
}

# Function to test Howdy
test_howdy() {
    echo "Testing Howdy configuration..."
    
    # Test if Howdy can detect face
    echo "Testing face detection..."
    sudo python3 /lib/security/howdy/cli.py test
    
    echo ""
    echo "To test authentication, try running: sudo -v"
    echo "Howdy should attempt facial recognition before falling back to password."
}

# Function to show configuration info
show_config_info() {
    echo "=== Howdy Configuration Information ==="
    echo "Main config file: /lib/security/howdy/config.ini"
    echo "Face models location: /lib/security/howdy/models/"
    echo ""
    echo "Useful commands:"
    echo "  sudo python3 /lib/security/howdy/cli.py add $USER              # Add face model"
    echo "  sudo python3 /lib/security/howdy/cli.py remove $USER           # Remove face model"
    echo "  sudo python3 /lib/security/howdy/cli.py list                   # List all models"
    echo "  sudo python3 /lib/security/howdy/cli.py test                   # Test face detection"
    echo "  sudo python3 /lib/security/howdy/cli.py config                 # Edit configuration"
    echo ""
    echo "Configuration tips:"
    echo "  - Adjust 'certainty' in config for sensitivity"
    echo "  - Set 'ignore_closed_lid = true' for laptops"
    echo "  - Configure 'timeout' for detection time limit"
}

# Main execution
main() {
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        echo "Please do not run this script as root (use your regular user account)"
        exit 1
    fi
    
    # Check system requirements
    check_system_requirements
    
    # Check for webcam
    if ! check_webcam; then
        echo "Cannot proceed without a webcam. Please connect a webcam and try again."
        exit 1
    fi
    
    # Select camera if multiple are available
    local camera_count=$(ls /dev/video* 2>/dev/null | wc -l)
    if [ "$camera_count" -gt 1 ]; then
        echo ""
        echo "Multiple cameras detected. Camera selection is recommended for best results."
        read -p "Would you like to select the camera interactively? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            selected_camera=$(select_camera)
            echo "Selected camera: $selected_camera"
        fi
    fi
    
    check_ir_camera
    
    # Check if Howdy is already installed
    if [ -f "/lib/security/howdy/cli.py" ] && [ -f "/lib/security/howdy/config.ini" ]; then
        echo "✓ Howdy is already installed"
        
        # Check if user has face models
        if sudo python3 /lib/security/howdy/cli.py list | grep -q "$USER"; then
            echo "✓ Face model already exists for user $USER"
            echo "You can add additional models with: sudo python3 /lib/security/howdy/cli.py add $USER"
        else
            echo "No face model found for user $USER"
            read -p "Would you like to add a face model now? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                setup_face_model
            fi
        fi
        
        test_howdy
        show_config_info
        
    else
        echo "Installing Howdy..."
        install_howdy
        
        # Verify dependencies after installation
        verify_dependencies
        
        configure_howdy
        setup_face_model
        test_howdy
        show_config_info
    fi
    
    echo ""
    echo "=== Howdy Setup Complete ==="
    echo "✓ Facial recognition authentication is now enabled"
    echo "✓ Howdy will work with sudo, su, and other PAM-enabled applications"
    echo ""
    echo "Security notes:"
    echo "  - Howdy is convenient but less secure than passwords alone"
    echo "  - Consider using it alongside other authentication methods"
    echo "  - Regular webcams can be spoofed easier than IR cameras"
    echo ""
    echo "To manage Howdy, use: ./howdy_manage.sh"
}

# Run main function
main
