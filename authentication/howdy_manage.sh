#!/bin/bash

# Howdy Management Script
# Enable, disable, configure, and manage Howdy facial recognition

set -e

SCRIPT_NAME="Howdy Manager"
PAM_BACKUP_SUFFIX=".howdy-backup"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to check if Howdy is installed
check_howdy_installed() {
    if [ -f "/lib/security/howdy/cli.py" ] && [ -f "/lib/security/howdy/config.ini" ]; then
        return 0
    else
        return 1
    fi
}

# Function to execute howdy commands
howdy_cmd() {
    python3 /lib/security/howdy/cli.py "$@"
}

# Function to check if Howdy is enabled in PAM
check_howdy_enabled() {
    if grep -q "pam_python.so.*howdy" /etc/pam.d/sudo 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to show Howdy status
show_status() {
    echo "=== Howdy Status ==="
    
    if check_howdy_installed; then
        print_status "Howdy is installed"
        echo "Version: $(howdy_cmd version 2>/dev/null | head -1 || echo 'Unknown')"
        
        if check_howdy_enabled; then
            print_status "Howdy is enabled in PAM"
        else
            print_warning "Howdy is disabled in PAM"
        fi
        
        # Show face models
        echo ""
        echo "Face models:"
        if howdy_cmd list | grep -q "$USER"; then
            howdy_cmd list | grep "$USER" | while read line; do
                print_status "$line"
            done
        else
            print_warning "No face models found for user $USER"
        fi
        
        # Show webcam status
        echo ""
        echo "Webcam status:"
        if ls /dev/video* >/dev/null 2>&1; then
            for cam in /dev/video*; do
                print_status "Camera found: $cam"
            done
        else
            print_error "No webcam detected"
        fi
        
    else
        print_error "Howdy is not installed"
        echo "Run ./setup_howdy.sh to install"
    fi
}

# Function to enable Howdy
enable_howdy() {
    echo "=== Enabling Howdy ==="
    
    if ! check_howdy_installed; then
        print_error "Howdy is not installed. Please run ./setup_howdy.sh first"
        return 1
    fi
    
    if check_howdy_enabled; then
        print_warning "Howdy is already enabled"
        return 0
    fi
    
    # Backup PAM configurations if not already backed up
    if [ ! -f "/etc/pam.d/sudo$PAM_BACKUP_SUFFIX" ]; then
        print_info "Backing up PAM configuration..."
        sudo cp /etc/pam.d/sudo "/etc/pam.d/sudo$PAM_BACKUP_SUFFIX"
        sudo cp /etc/pam.d/su "/etc/pam.d/su$PAM_BACKUP_SUFFIX"
    fi
    
    # Enable Howdy in PAM
    print_info "Enabling Howdy in PAM configuration..."
    
    # Add to sudo
    if ! grep -q "pam_python.so.*howdy" /etc/pam.d/sudo; then
        sudo sed -i '1i auth sufficient pam_python.so /lib/security/howdy/pam.py' /etc/pam.d/sudo
    fi
    
    # Add to su
    if ! grep -q "pam_python.so.*howdy" /etc/pam.d/su; then
        sudo sed -i '1i auth sufficient pam_python.so /lib/security/howdy/pam.py' /etc/pam.d/su
    fi
    
    print_status "Howdy enabled successfully"
    print_info "You can now use facial recognition for authentication"
}

# Function to disable Howdy
disable_howdy() {
    echo "=== Disabling Howdy ==="
    
    if ! check_howdy_enabled; then
        print_warning "Howdy is already disabled"
        return 0
    fi
    
    print_info "Disabling Howdy in PAM configuration..."
    
    # Remove Howdy from PAM configs
    sudo sed -i '/pam_python.so.*howdy/d' /etc/pam.d/sudo
    sudo sed -i '/pam_python.so.*howdy/d' /etc/pam.d/su
    
    print_status "Howdy disabled successfully"
    print_info "Facial recognition authentication is now disabled"
}

# Function to completely remove Howdy
remove_howdy() {
    echo "=== Removing Howdy ==="
    
    read -p "Are you sure you want to completely remove Howdy? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Removal cancelled"
        return 0
    fi
    
    # First disable Howdy
    disable_howdy
    
    # Restore original PAM configurations
    if [ -f "/etc/pam.d/sudo$PAM_BACKUP_SUFFIX" ]; then
        print_info "Restoring original PAM configuration..."
        sudo cp "/etc/pam.d/sudo$PAM_BACKUP_SUFFIX" /etc/pam.d/sudo
        sudo cp "/etc/pam.d/su$PAM_BACKUP_SUFFIX" /etc/pam.d/su
        sudo rm -f "/etc/pam.d/sudo$PAM_BACKUP_SUFFIX"
        sudo rm -f "/etc/pam.d/su$PAM_BACKUP_SUFFIX"
    fi
    
    # Remove Howdy package
    if check_howdy_installed; then
        print_info "Removing Howdy package..."
        
        # Try to remove via package manager first
        if sudo apt remove howdy -y 2>/dev/null; then
            print_status "Howdy removed via package manager"
        else
            # Manual removal for source installations
            print_info "Removing Howdy files manually..."
            sudo rm -rf /lib/security/howdy/ 2>/dev/null || true
            sudo rm -f /usr/local/bin/howdy 2>/dev/null || true
            sudo rm -f /usr/bin/howdy 2>/dev/null || true
        fi
    fi
    
    print_status "Howdy has been completely removed"
}

# Function to add face model
add_face() {
    echo "=== Adding Face Model ==="
    
    if ! check_howdy_installed; then
        print_error "Howdy is not installed"
        return 1
    fi
    
    echo "Please look at the camera and ensure good lighting"
    read -p "Press Enter to capture face model..."
    
    sudo howdy_cmd add $USER
    
    if [ $? -eq 0 ]; then
        print_status "Face model added successfully"
    else
        print_error "Failed to add face model"
    fi
}

# Function to remove face model
remove_face() {
    echo "=== Removing Face Model ==="
    
    if ! check_howdy_installed; then
        print_error "Howdy is not installed"
        return 1
    fi
    
    # List current models
    echo "Current face models:"
    sudo howdy_cmd list
    
    read -p "Enter the ID of the model to remove (or press Enter to cancel): " model_id
    
    if [ -n "$model_id" ]; then
        sudo howdy_cmd remove $model_id
        if [ $? -eq 0 ]; then
            print_status "Face model removed successfully"
        else
            print_error "Failed to remove face model"
        fi
    else
        echo "Removal cancelled"
    fi
}

# Function to test Howdy
test_howdy() {
    echo "=== Testing Howdy ==="
    
    if ! check_howdy_installed; then
        print_error "Howdy is not installed"
        return 1
    fi
    
    if ! check_howdy_enabled; then
        print_error "Howdy is disabled. Enable it first with: $0 enable"
        return 1
    fi
    
    print_info "Testing face detection..."
    sudo howdy_cmd test
    
    echo ""
    print_info "To test authentication, try: sudo -v"
}

# Function to configure Howdy
configure_howdy() {
    echo "=== Howdy Configuration ==="
    
    if ! check_howdy_installed; then
        print_error "Howdy is not installed"
        return 1
    fi
    
    print_info "Opening Howdy configuration..."
    sudo howdy_cmd config
}

# Function to show help
show_help() {
    echo "=== Howdy Management Script ==="
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  status      - Show Howdy status and configuration"
    echo "  enable      - Enable Howdy facial recognition"
    echo "  disable     - Disable Howdy (keeps installation)"
    echo "  remove      - Completely remove Howdy"
    echo "  add         - Add face model for current user"
    echo "  remove-face - Remove face model"
    echo "  test        - Test Howdy face detection"
    echo "  config      - Edit Howdy configuration"
    echo "  help        - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 status           # Check current status"
    echo "  $0 enable           # Enable facial recognition"
    echo "  $0 disable          # Disable facial recognition"
    echo "  $0 add              # Add your face model"
    echo "  $0 test             # Test face detection"
    echo ""
    echo "Security notes:"
    echo "  - Howdy provides convenience but may be less secure than passwords"
    echo "  - Works best with IR cameras (Windows Hello compatible)"
    echo "  - Regular webcams can potentially be spoofed"
}

# Main execution
main() {
    case "${1:-status}" in
        "status")
            show_status
            ;;
        "enable")
            enable_howdy
            ;;
        "disable")
            disable_howdy
            ;;
        "remove")
            remove_howdy
            ;;
        "add")
            add_face
            ;;
        "remove-face")
            remove_face
            ;;
        "test")
            test_howdy
            ;;
        "config")
            configure_howdy
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run this script as root (use your regular user account)"
    exit 1
fi

# Run main function
main "$@"
