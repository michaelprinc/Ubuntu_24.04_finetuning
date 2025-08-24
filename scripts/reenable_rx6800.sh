#!/bin/bash

# RX 6800 GPU Re-enablement Script
# Standalone script to restore GPU functionality after VM passthrough

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Configuration - Update these with your actual GPU PCI IDs
# Find your IDs with: lspci -nn | grep -E "(VGA|Audio).*AMD"
RX6800_VGA_ID="1002:73bf"  # RX 6800 VGA controller (detected: Navi 21)
RX6800_AUDIO_ID="1002:ab28"  # RX 6800 Audio controller
RX6800_PCI_SLOT=""  # Will be auto-detected or set manually

# Auto-detect RX 6800 PCI slot
detect_gpu_pci_slot() {
    log "=== Detecting RX 6800 PCI Slot ==="
    
    # Look for RX 6800 by device ID
    local vga_slot=$(lspci -d "1002:73bf" | cut -d' ' -f1 | head -1)
    local audio_slot=$(lspci -d "1002:ab28" | cut -d' ' -f1 | head -1)
    
    if [ -n "$vga_slot" ]; then
        RX6800_PCI_SLOT="$vga_slot"
        info "Detected RX 6800 VGA at PCI slot: $RX6800_PCI_SLOT"
        
        if [ -n "$audio_slot" ]; then
            info "Detected RX 6800 Audio at PCI slot: $audio_slot"
        fi
    else
        warning "Could not auto-detect RX 6800. Checking all AMD GPUs:"
        lspci | grep -E "(VGA|Display|Audio).*AMD"
        echo ""
        warning "Please update the script with correct PCI IDs and slots"
        return 1
    fi
}

# Check current GPU status
check_gpu_status() {
    log "=== Current GPU Status ==="
    
    echo "AMD GPU devices:"
    lspci | grep -E "(VGA|Display|Audio).*AMD"
    
    echo ""
    echo "Loaded GPU modules:"
    lsmod | grep -E "(amdgpu|radeon)" || echo "No AMD GPU modules loaded"
    
    echo ""
    echo "VFIO bound devices:"
    find /sys/bus/pci/drivers/vfio-pci -name "0000:*" 2>/dev/null | while read device; do
        local pci_id=$(basename "$device")
        local device_info=$(lspci -s "${pci_id#0000:}")
        echo "  $pci_id: $device_info"
    done || echo "No VFIO bound devices found"
    
    echo ""
    echo "AMDGPU bound devices:"
    find /sys/bus/pci/drivers/amdgpu -name "0000:*" 2>/dev/null | while read device; do
        local pci_id=$(basename "$device")
        local device_info=$(lspci -s "${pci_id#0000:}")
        echo "  $pci_id: $device_info"
    done || echo "No AMDGPU bound devices found"
}

# Stop any running VMs that might be using the GPU
stop_gpu_vms() {
    log "=== Stopping VMs Using GPU ==="
    
    # Check for running VMs
    local running_vms=$(virsh list --state-running --name 2>/dev/null || echo "")
    
    if [ -n "$running_vms" ]; then
        warning "Found running VMs. Attempting to stop them:"
        echo "$running_vms" | while read vm_name; do
            if [ -n "$vm_name" ]; then
                info "Stopping VM: $vm_name"
                virsh shutdown "$vm_name" 2>/dev/null || warning "Failed to gracefully shutdown $vm_name"
            fi
        done
        
        # Wait a bit for graceful shutdown
        info "Waiting 10 seconds for VMs to shutdown gracefully..."
        sleep 10
        
        # Force stop if still running
        running_vms=$(virsh list --state-running --name 2>/dev/null || echo "")
        if [ -n "$running_vms" ]; then
            warning "Force stopping remaining VMs:"
            echo "$running_vms" | while read vm_name; do
                if [ -n "$vm_name" ]; then
                    virsh destroy "$vm_name" 2>/dev/null || warning "Failed to force stop $vm_name"
                fi
            done
        fi
    else
        info "No running VMs found"
    fi
}

# Unbind GPU from VFIO driver
unbind_from_vfio() {
    log "=== Unbinding GPU from VFIO ==="
    
    if [ -z "$RX6800_PCI_SLOT" ]; then
        error "RX6800_PCI_SLOT not set. Cannot proceed."
        return 1
    fi
    
    local full_pci_slot="0000:$RX6800_PCI_SLOT"
    
    # Check if bound to VFIO
    if [ -e "/sys/bus/pci/drivers/vfio-pci/$full_pci_slot" ]; then
        info "Unbinding $full_pci_slot from vfio-pci"
        echo "$full_pci_slot" | sudo tee /sys/bus/pci/drivers/vfio-pci/unbind > /dev/null
        sleep 2
    else
        info "GPU not bound to vfio-pci driver"
    fi
    
    # Also unbind audio device if present
    local audio_pci_slot=$(lspci -d "1002:ab28" | cut -d' ' -f1 | head -1)
    if [ -n "$audio_pci_slot" ]; then
        local full_audio_slot="0000:$audio_pci_slot"
        if [ -e "/sys/bus/pci/drivers/vfio-pci/$full_audio_slot" ]; then
            info "Unbinding $full_audio_slot from vfio-pci"
            echo "$full_audio_slot" | sudo tee /sys/bus/pci/drivers/vfio-pci/unbind > /dev/null
            sleep 2
        fi
    fi
}

# Bind GPU to AMDGPU driver
bind_to_amdgpu() {
    log "=== Binding GPU to AMDGPU Driver ==="
    
    # Load amdgpu module if not loaded
    if ! lsmod | grep -q amdgpu; then
        info "Loading amdgpu module"
        sudo modprobe amdgpu
        sleep 3
    fi
    
    # Bind GPU to amdgpu driver
    if [ -n "$RX6800_PCI_SLOT" ]; then
        local full_pci_slot="0000:$RX6800_PCI_SLOT"
        
        # Remove device from any driver first
        if [ -e "/sys/bus/pci/devices/$full_pci_slot/driver" ]; then
            info "Removing device from current driver"
            echo "$full_pci_slot" | sudo tee /sys/bus/pci/devices/$full_pci_slot/driver/unbind > /dev/null 2>&1 || true
            sleep 2
        fi
        
        # Bind to amdgpu
        info "Binding $full_pci_slot to amdgpu driver"
        echo "$full_pci_slot" | sudo tee /sys/bus/pci/drivers/amdgpu/bind > /dev/null 2>&1 || {
            # Alternative method: use device ID
            info "Direct bind failed, trying device ID method"
            echo "$RX6800_VGA_ID" | sudo tee /sys/bus/pci/drivers/amdgpu/new_id > /dev/null 2>&1 || true
        }
        sleep 3
    fi
}

# Restart display manager
restart_display_manager() {
    log "=== Restarting Display Manager ==="
    
    # Detect display manager
    local dm=""
    if systemctl is-active gdm3 &>/dev/null; then
        dm="gdm3"
    elif systemctl is-active lightdm &>/dev/null; then
        dm="lightdm"
    elif systemctl is-active sddm &>/dev/null; then
        dm="sddm"
    elif systemctl is-active xdm &>/dev/null; then
        dm="xdm"
    fi
    
    if [ -n "$dm" ]; then
        warning "Restarting display manager: $dm"
        warning "This will close your current session!"
        
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo systemctl restart "$dm"
        else
            info "Skipping display manager restart"
            info "You may need to restart manually or reboot for full GPU functionality"
        fi
    else
        warning "Could not detect display manager"
        info "You may need to restart your session manually"
    fi
}

# Verify GPU restoration
verify_gpu_restoration() {
    log "=== Verifying GPU Restoration ==="
    
    echo "Current GPU driver binding:"
    check_gpu_status
    
    echo ""
    echo "Testing GPU functionality:"
    
    # Test DRM devices
    if ls /dev/dri/card* &>/dev/null; then
        info "✓ DRM devices available:"
        ls -la /dev/dri/card*
    else
        warning "✗ No DRM devices found"
    fi
    
    # Test Vulkan
    if command -v vulkaninfo &>/dev/null; then
        echo ""
        info "Testing Vulkan support..."
        if vulkaninfo --summary &>/dev/null; then
            info "✓ Vulkan support working"
            vulkaninfo --summary | head -10
        else
            warning "✗ Vulkan not working properly"
        fi
    fi
    
    # Test OpenCL
    if command -v clinfo &>/dev/null; then
        echo ""
        info "Testing OpenCL support..."
        if clinfo -l &>/dev/null; then
            info "✓ OpenCL support working"
            clinfo -l
        else
            warning "✗ OpenCL not working properly"
        fi
    fi
    
    # Test glxinfo if available
    if command -v glxinfo &>/dev/null; then
        echo ""
        info "Testing OpenGL support..."
        local renderer=$(glxinfo | grep "OpenGL renderer" 2>/dev/null || echo "Not available")
        info "OpenGL renderer: $renderer"
    fi
}

# Cleanup VFIO configuration (optional)
cleanup_vfio_config() {
    log "=== VFIO Configuration Cleanup ==="
    
    warning "This will modify VFIO configuration files"
    read -p "Temporarily disable VFIO GPU binding? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Backup and modify VFIO configuration
        if [ -f "/etc/modprobe.d/vfio.conf" ]; then
            info "Backing up VFIO configuration"
            sudo cp /etc/modprobe.d/vfio.conf /etc/modprobe.d/vfio.conf.backup
            
            # Comment out the GPU binding temporarily
            sudo sed -i 's/^options vfio-pci ids=/# options vfio-pci ids=/' /etc/modprobe.d/vfio.conf
            sudo sed -i 's/^softdep amdgpu pre:/# softdep amdgpu pre:/' /etc/modprobe.d/vfio.conf
            
            info "VFIO configuration temporarily disabled"
            info "To re-enable: sudo cp /etc/modprobe.d/vfio.conf.backup /etc/modprobe.d/vfio.conf"
        fi
    else
        info "VFIO configuration unchanged"
    fi
}

# Show usage
show_usage() {
    echo "RX 6800 GPU Re-enablement Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --status       Show current GPU status only"
    echo "  --auto         Run full restoration automatically"
    echo "  --no-dm        Skip display manager restart"
    echo "  --cleanup      Also cleanup VFIO configuration"
    echo "  --help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0             Interactive mode (recommended)"
    echo "  $0 --auto     Automatic restoration"
    echo "  $0 --status   Check current status"
}

# Main function
main() {
    local auto_mode=false
    local skip_dm=false
    local cleanup_vfio=false
    local status_only=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --auto)
                auto_mode=true
                shift
                ;;
            --no-dm)
                skip_dm=true
                shift
                ;;
            --cleanup)
                cleanup_vfio=true
                shift
                ;;
            --status)
                status_only=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    log "=== RX 6800 GPU Re-enablement Started ==="
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        error "Do not run this script as root. It will sudo when needed."
        exit 1
    fi
    
    # Status check only
    if [ "$status_only" = true ]; then
        detect_gpu_pci_slot || true
        check_gpu_status
        exit 0
    fi
    
    # Detect GPU
    if ! detect_gpu_pci_slot; then
        error "Failed to detect RX 6800. Please update script configuration."
        exit 1
    fi
    
    # Show current status
    check_gpu_status
    
    echo ""
    if [ "$auto_mode" = false ]; then
        warning "This script will:"
        warning "1. Stop any running VMs using the GPU"
        warning "2. Unbind GPU from VFIO driver"
        warning "3. Bind GPU to AMDGPU driver"
        warning "4. Restart display manager (closes current session)"
        echo ""
        read -p "Continue with GPU restoration? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Operation cancelled"
            exit 0
        fi
    fi
    
    # Execute restoration steps
    stop_gpu_vms
    unbind_from_vfio
    bind_to_amdgpu
    
    # Optional VFIO cleanup
    if [ "$cleanup_vfio" = true ]; then
        cleanup_vfio_config
    fi
    
    # Restart display manager unless skipped
    if [ "$skip_dm" = false ]; then
        restart_display_manager
    fi
    
    # Final verification
    echo ""
    verify_gpu_restoration
    
    log "=== RX 6800 GPU Re-enablement Complete ==="
    
    if [ "$skip_dm" = true ]; then
        warning "Display manager restart was skipped"
        warning "You may need to restart your session or reboot for full functionality"
    fi
    
    info "GPU should now be available for host use"
    info "Test with: glxinfo, vulkaninfo, or radeontop"
}

# Run main function with all arguments
main "$@"
