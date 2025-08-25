#!/bin/bash

# Test script to install and verify dlib and face_recognition dependencies
# This script tests the dependency installation part without installing Howdy

set -e

echo "=== Testing Dependency Installation ==="

# Function to install Python dependencies
install_python_deps() {
    echo "Installing Python dependencies..."
    
    # Install core dependencies
    pip3 install --user --upgrade pip setuptools wheel
    
    # Install numpy first (required for dlib compilation)
    pip3 install --user numpy
    
    # Install dlib (this can take several minutes to compile)
    echo "Installing dlib (this may take 5-15 minutes to compile)..."
    echo "Note: The build may appear to hang at 100% - please be patient!"
    
    pip3 install --user dlib
    
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
}

# Function to verify dependencies
verify_deps() {
    echo "Verifying installed dependencies..."
    local failed=0
    
    # Check Python packages
    echo "Checking Python packages..."
    local python_deps=("numpy" "cv2" "dlib" "face_recognition")
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
        echo "❌ Some dependencies failed to install"
        return 1
    else
        echo "✅ All dependencies installed successfully"
        return 0
    fi
}

# Main execution
echo "This will install dlib and face_recognition libraries."
echo "The installation may take 10-20 minutes due to compilation."
echo ""

read -p "Continue with dependency installation? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

echo ""
echo "Starting dependency installation..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

install_python_deps

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Installation complete! Verifying..."

verify_deps

echo ""
echo "🎉 Dependency test complete!"
echo "You can now run ./setup_howdy.sh to install Howdy."
