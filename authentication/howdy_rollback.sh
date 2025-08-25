#!/bin/bash

# Howdy Rollback Script
# Completely removes Howdy and restores original authentication

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

echo "=== Howdy Complete Rollback ==="
echo "This script will completely remove Howdy and restore original authentication"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run this script as root (use your regular user account)"
    exit 1
fi

# Confirmation prompt
read -p "Are you sure you want to completely remove Howdy? This cannot be undone. (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Rollback cancelled"
    exit 0
fi

print_info "Starting Howdy rollback process..."

# Step 1: Remove Howdy from PAM configuration
print_info "Removing Howdy from PAM authentication..."

# Remove Howdy entries from PAM files
sudo sed -i '/pam_python.so.*howdy/d' /etc/pam.d/sudo 2>/dev/null || true
sudo sed -i '/pam_python.so.*howdy/d' /etc/pam.d/su 2>/dev/null || true
sudo sed -i '/pam_python.so.*howdy/d' /etc/pam.d/gdm-password 2>/dev/null || true
sudo sed -i '/pam_python.so.*howdy/d' /etc/pam.d/login 2>/dev/null || true

print_status "PAM configuration cleaned"

# Step 2: Restore backup PAM configurations if they exist
if [ -f "/etc/pam.d/sudo.howdy-backup" ]; then
    print_info "Restoring original PAM configurations..."
    sudo cp /etc/pam.d/sudo.howdy-backup /etc/pam.d/sudo
    sudo cp /etc/pam.d/su.howdy-backup /etc/pam.d/su
    sudo rm -f /etc/pam.d/sudo.howdy-backup
    sudo rm -f /etc/pam.d/su.howdy-backup
    print_status "Original PAM configurations restored"
fi

# Step 3: Stop any Howdy services
print_info "Stopping Howdy services..."
sudo systemctl stop howdy 2>/dev/null || true
sudo systemctl disable howdy 2>/dev/null || true

# Step 4: Remove Howdy package
print_info "Removing Howdy package..."

# Try package manager removal first
if dpkg -l | grep -q howdy; then
    sudo apt remove --purge howdy -y 2>/dev/null || true
    sudo apt autoremove -y 2>/dev/null || true
fi

# Step 5: Manual cleanup of Howdy files
print_info "Cleaning up Howdy files..."

# Remove Howdy directories and files
sudo rm -rf /lib/security/howdy/ 2>/dev/null || true
sudo rm -rf /usr/lib/security/howdy/ 2>/dev/null || true
sudo rm -f /usr/local/bin/howdy 2>/dev/null || true
sudo rm -f /usr/bin/howdy 2>/dev/null || true
sudo rm -f /bin/howdy 2>/dev/null || true
sudo rm -rf /var/lib/howdy/ 2>/dev/null || true
sudo rm -rf /etc/howdy/ 2>/dev/null || true

# Remove configuration files
sudo rm -f /etc/howdy.conf 2>/dev/null || true
sudo rm -rf ~/.config/howdy/ 2>/dev/null || true

# Remove any systemd services
sudo rm -f /etc/systemd/system/howdy.service 2>/dev/null || true
sudo rm -f /lib/systemd/system/howdy.service 2>/dev/null || true
sudo systemctl daemon-reload 2>/dev/null || true

print_status "Howdy files removed"

# Step 6: Remove dependencies (optional)
print_info "Checking for unused dependencies..."

read -p "Remove Howdy dependencies (opencv, dlib, etc.)? This may affect other applications. (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Removing Howdy dependencies..."
    
    # Remove Python packages
    pip3 uninstall dlib face_recognition opencv-python -y 2>/dev/null || true
    
    # Remove system packages (be careful here)
    sudo apt remove libopencv-dev python3-opencv -y 2>/dev/null || true
    sudo apt autoremove -y 2>/dev/null || true
    
    print_status "Dependencies removed"
else
    print_info "Keeping dependencies (recommended)"
fi

# Step 7: Verify removal
print_info "Verifying Howdy removal..."

# Check if Howdy command exists
if command -v howdy >/dev/null 2>&1; then
    print_warning "Howdy command still exists, but PAM integration removed"
else
    print_status "Howdy command removed"
fi

# Check PAM configuration
if grep -q "howdy" /etc/pam.d/sudo 2>/dev/null; then
    print_warning "Howdy still found in PAM configuration"
else
    print_status "PAM configuration clean"
fi

# Step 8: Final verification
print_info "Testing authentication..."
echo "Please test sudo authentication to ensure it works normally:"
echo "Try running: sudo -v"
echo ""

# Step 9: Cleanup script completion
print_status "Howdy rollback completed successfully!"
echo ""
echo "Summary of changes:"
echo "  ✓ Howdy removed from PAM authentication"
echo "  ✓ Original PAM configurations restored"
echo "  ✓ Howdy package and files removed"
echo "  ✓ Howdy services disabled"
echo ""
echo "Your system has been restored to password-only authentication."
echo ""

# Optional: Create rollback log
LOG_FILE="/tmp/howdy_rollback_$(date +%Y%m%d_%H%M%S).log"
{
    echo "Howdy Rollback Log - $(date)"
    echo "================================"
    echo "User: $USER"
    echo "System: $(uname -a)"
    echo "Rollback completed successfully"
    echo "Authentication restored to password-only"
} > "$LOG_FILE"

print_info "Rollback log saved to: $LOG_FILE"

# Final reminder
echo ""
print_warning "Reminder: If you experience any authentication issues:"
echo "1. Reboot your system"
echo "2. Use recovery mode if needed"
echo "3. Check PAM configuration in /etc/pam.d/"
echo ""
echo "You can reinstall Howdy later using: ./setup_howdy.sh"
