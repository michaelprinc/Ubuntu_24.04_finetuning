#!/bin/bash

# Camera Selection Tool for Howdy
# Allows user to cycle through available cameras and select the best one

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

echo "=== Howdy Camera Selection Tool ==="

# Check if required tools are available
check_dependencies() {
    local missing_deps=()
    
    if ! command -v fswebcam >/dev/null 2>&1; then
        missing_deps+=(fswebcam)
    fi
    
    if ! command -v v4l2-ctl >/dev/null 2>&1; then
        missing_deps+=(v4l-utils)
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_warning "Installing required dependencies: ${missing_deps[*]}"
        sudo apt update
        sudo apt install -y "${missing_deps[@]}"
    fi
}

# Function to get camera info
get_camera_info() {
    local device="$1"
    local info=""
    
    # Get camera name and capabilities
    if command -v v4l2-ctl >/dev/null 2>&1; then
        local name
        name=$(v4l2-ctl -d "$device" --info 2>/dev/null | grep "Card type" | cut -d: -f2 | xargs)
        if [ -n "$name" ]; then
            info="$name"
        else
            info="Video Device $(basename "$device")"
        fi
    else
        info="Camera device"
    fi
    
    echo "$info"
}

# Function to test camera with preview
test_camera() {
    local device="$1"
    local device_name
    device_name=$(basename "$device")
    local output_file="/tmp/howdy_camera_test_${device_name}.jpg"
    
    print_info "Testing camera: $device"
    print_info "Camera info: $(get_camera_info "$device")"
    
    # Capture test image
    if fswebcam -d "$device" -r 640x480 --no-banner "$output_file" 2>/dev/null; then
        print_status "Test image captured: $output_file"
        
        # Try to display the image if GUI is available
        if [ -n "$DISPLAY" ] && command -v xdg-open >/dev/null 2>&1; then
            print_info "Opening preview image..."
            xdg-open "$output_file" 2>/dev/null &
            local preview_pid=$!
            
            echo ""
            echo "Preview image should now be displayed."
            echo "You can see what this camera captures."
            echo ""
            
            # Wait a moment for image to load
            sleep 2
            
            # Kill the preview after user decides
            read -p "Use this camera for Howdy? (y/N): " -n 1 -r
            echo
            
            # Close preview
            kill $preview_pid 2>/dev/null || true
            
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -f "$output_file"
                return 0
            fi
        else
            print_warning "No GUI available for image preview"
            print_info "Image saved to: $output_file"
            print_info "You can view it manually to check camera quality"
            echo ""
            read -p "Use this camera for Howdy? (y/N): " -n 1 -r
            echo
            
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -f "$output_file"
                return 0
            fi
        fi
        
        rm -f "$output_file"
        return 1
    else
        print_error "Failed to capture from $device"
        return 1
    fi
}

# Function to list all video devices
list_cameras() {
    local cameras=()
    
    # Check each video device
    for device in /dev/video*; do
        # Skip if glob expansion didn't match any files
        [ -e "$device" ] || continue
        
        # Check if it's a character device
        if [ -c "$device" ]; then
            # Check if it's a capture device
            if v4l2-ctl -d "$device" --list-formats >/dev/null 2>&1; then
                # Verify it has capture capability
                local formats
                formats=$(v4l2-ctl -d "$device" --list-formats 2>/dev/null)
                if echo "$formats" | grep -q "Video Capture"; then
                    cameras+=("$device")
                fi
            fi
        fi
    done
    
    if [ ${#cameras[@]} -eq 0 ]; then
        print_error "No cameras detected!" >&2
        return 1
    fi
    
    # Print cameras one per line for proper parsing
    printf '%s\n' "${cameras[@]}"
}

# Function to get camera resolution and format info
get_camera_details() {
    local device="$1"
    
    echo "Camera: $device"
    echo "Info: $(get_camera_info "$device")"
    
    if command -v v4l2-ctl >/dev/null 2>&1; then
        echo "Formats:"
        v4l2-ctl -d "$device" --list-formats-ext 2>/dev/null | head -10 | sed 's/^/  /' || echo "  Unable to query formats"
    fi
    echo ""
}

# Main camera selection function
select_camera() {
    print_info "Scanning for available cameras..."
    local cameras=()
    
    # Read cameras into array properly
    while IFS= read -r camera; do
        cameras+=("$camera")
    done < <(list_cameras)
    
    if [ ${#cameras[@]} -eq 0 ]; then
        return 1
    fi
    
    print_status "Found ${#cameras[@]} camera(s)"
    echo ""
    
    # Show details for all cameras first
    print_info "Available cameras:"
    for device in "${cameras[@]}"; do
        get_camera_details "$device"
    done
    
    # Test each camera
    print_info "Testing cameras (you'll see a preview for each)..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    for device in "${cameras[@]}"; do
        echo ""
        print_info "Camera: $device"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        if test_camera "$device"; then
            print_status "Selected camera: $device"
            echo "$device"
            return 0
        fi
        
        echo ""
        print_info "Moving to next camera..."
        sleep 1
    done
    
    # If no camera was selected, ask if user wants to manually specify
    echo ""
    print_warning "No camera was selected."
    read -p "Would you like to manually specify a camera device? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter camera device path (e.g., /dev/video0): " manual_device
        if [ -c "$manual_device" ]; then
            print_status "Using manually specified camera: $manual_device"
            echo "$manual_device"
            return 0
        else
            print_error "Invalid device: $manual_device"
            return 1
        fi
    fi
    
    return 1
}

# Function to recommend best camera
recommend_camera() {
    print_info "Scanning for camera recommendations..."
    local cameras=()
    
    # Read cameras into array properly
    while IFS= read -r camera; do
        cameras+=("$camera")
    done < <(list_cameras 2>/dev/null)
    
    if [ ${#cameras[@]} -eq 0 ]; then
        print_warning "No cameras found for recommendations"
        return 1
    fi
    
    print_info "Camera recommendations:"
    echo ""
    
    for device in "${cameras[@]}"; do
        local info=$(get_camera_info "$device")
        echo "📷 $device - $info"
        
        # Check for IR camera indicators
        if echo "$info" | grep -qi "infrared\|ir\|windows\|hello"; then
            print_status "  Recommended: Likely IR camera (better security)"
        elif echo "$info" | grep -qi "integrated\|built.?in\|laptop"; then
            print_info "  Good choice: Integrated camera"
        else
            print_info "  Standard: Regular webcam"
        fi
        echo ""
    done
}

# Test mode function
run_tests() {
    echo "=== Running Camera Selection Tests ==="
    echo ""
    
    print_info "Test 1: Dependencies check"
    check_dependencies
    print_status "Dependencies test passed"
    echo ""
    
    print_info "Test 2: Camera discovery"
    print_info "Scanning for available cameras..."
    local cameras=()
    while IFS= read -r camera; do
        cameras+=("$camera")
    done < <(list_cameras)
    
    if [ ${#cameras[@]} -gt 0 ]; then
        print_status "Camera discovery test passed: found ${#cameras[@]} cameras"
        for camera in "${cameras[@]}"; do
            echo "  - $camera"
        done
    else
        print_error "Camera discovery test failed: no cameras found"
        return 1
    fi
    echo ""
    
    print_info "Test 3: Camera info retrieval"
    for camera in "${cameras[@]}"; do
        local info
        info=$(get_camera_info "$camera")
        print_status "Camera $camera: $info"
    done
    echo ""
    
    print_info "Test 4: Camera capture test (first camera only)"
    if [ ${#cameras[@]} -gt 0 ]; then
        local test_file="/tmp/camera_test_$(date +%s).jpg"
        if timeout 10 fswebcam -d "${cameras[0]}" -r 320x240 --no-banner "$test_file" >/dev/null 2>&1; then
            if [ -f "$test_file" ] && [ -s "$test_file" ]; then
                print_status "Camera capture test passed"
                rm -f "$test_file"
            else
                print_error "Camera capture test failed: empty or missing file"
                return 1
            fi
        else
            print_error "Camera capture test failed: fswebcam error"
            return 1
        fi
    fi
    echo ""
    
    print_status "All tests passed!"
    return 0
}

# Main execution
main() {
    # Check for test mode
    if [ "${1:-}" = "test" ]; then
        run_tests
        exit $?
    fi
    echo "This tool helps you select the right camera for Howdy facial recognition."
    echo ""
    
    # Check dependencies
    check_dependencies
    
    # Show recommendations
    recommend_camera
    
    echo "Now we'll test each camera so you can choose the best one."
    echo "You'll see a preview image for each camera."
    echo ""
    
    read -p "Ready to start camera testing? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Camera selection cancelled."
        exit 1
    fi
    
    # Select camera
    selected_camera=$(select_camera)
    
    if [ $? -eq 0 ] && [ -n "$selected_camera" ]; then
        echo ""
        print_status "Camera selection completed!"
        print_status "Selected camera: $selected_camera"
        echo ""
        
        # Save selection to a file for other scripts to use
        echo "$selected_camera" > /tmp/howdy_selected_camera
        
        print_info "Camera selection saved to: /tmp/howdy_selected_camera"
        print_info "You can now run the Howdy setup script."
        
        # Ask if user wants to continue with Howdy setup
        echo ""
        read -p "Would you like to run Howdy setup now with this camera? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            print_info "Starting Howdy setup with selected camera..."
            exec ./setup_howdy.sh
        fi
        
    else
        print_error "No camera was selected. Howdy setup cannot continue."
        print_info "Please run this script again to select a camera."
        exit 1
    fi
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run this script as root (use your regular user account)"
    exit 1
fi

# Run main function with command line arguments
main "$@"
