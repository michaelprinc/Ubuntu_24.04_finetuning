#!/bin/bash

# Ubuntu 24.04.3 Master Setup Script
# Implements all features from the implementation plan

set -e

SCRIPT_DIR="/media/michael-princ/E85AE8F65AE8C284/Data_science_projects/Ubuntu_24.04_fine_tuning/scripts"
LOG_FILE="/media/michael-princ/E85AE8F65AE8C284/Data_science_projects/Ubuntu_24.04_fine_tuning/setup.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

# Check if script is run with appropriate privileges
check_privileges() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root directly"
        error "It will prompt for sudo when needed"
        exit 1
    fi
    
    # Check if user can sudo
    if ! sudo -n true 2>/dev/null; then
        info "This script requires sudo privileges"
        sudo -v
    fi
}

# Pre-flight checks
pre_flight_check() {
    log "=== Pre-flight Checks ==="
    
    # Check Ubuntu version
    if ! grep -q "24.04" /etc/lsb-release; then
        warning "This script is designed for Ubuntu 24.04. Current version:"
        cat /etc/lsb-release
    fi
    
    # Check internet connectivity
    if ! ping -c 1 google.com &> /dev/null; then
        error "No internet connectivity detected"
        exit 1
    fi
    
    # Check available disk space (at least 10GB free)
    available_space=$(df / | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt 10485760 ]; then  # 10GB in KB
        warning "Low disk space detected. Consider freeing up space."
    fi
    
    log "Pre-flight checks completed"
}

# Make all scripts executable
make_executable() {
    log "Making all scripts executable..."
    chmod +x "$SCRIPT_DIR"/*.sh
}

# Run individual setup scripts
run_setup_phase() {
    local phase=$1
    local script=$2
    local description=$3
    
    log "=== Phase $phase: $description ==="
    
    if [ -f "$SCRIPT_DIR/$script" ]; then
        info "Running $script..."
        bash "$SCRIPT_DIR/$script" 2>&1 | tee -a "$LOG_FILE"
        
        if [ ${PIPESTATUS[0]} -eq 0 ]; then
            log "✅ Phase $phase completed successfully"
        else
            error "❌ Phase $phase failed"
            return 1
        fi
    else
        error "Script $script not found"
        return 1
    fi
}

# Main setup function
main_setup() {
    local phases_to_run=$1
    
    log "=== Ubuntu 24.04.3 Enhanced Setup Started ==="
    log "Timestamp: $(date)"
    log "User: $USER"
    log "Hostname: $(hostname)"
    log "Kernel: $(uname -r)"
    
    case $phases_to_run in
        "all"|"")
            run_setup_phase 1 "01_networking_drivers.sh" "Networking & Drivers"
            run_setup_phase 2 "02_security_hardening.sh" "Security Hardening"
            run_setup_phase 3 "03_performance_tuning.sh" "Performance & Hardware Acceleration"
            run_setup_phase 4 "04_gpu_compute_stack.sh" "GPU / Compute Stack"
            run_setup_phase 5 "05_virtualization_passthrough.sh" "Virtualization & GPU Passthrough"
            run_setup_phase 6 "06_docker_development.sh" "Docker & Development"
            run_setup_phase 7 "07_developer_qol.sh" "Developer Quality of Life"
            run_setup_phase 8 "08_backup_resilience.sh" "Backup & Resilience"
            ;;
        "1")
            run_setup_phase 1 "01_networking_drivers.sh" "Networking & Drivers"
            ;;
        "2")
            run_setup_phase 2 "02_security_hardening.sh" "Security Hardening"
            ;;
        "3")
            run_setup_phase 3 "03_performance_tuning.sh" "Performance & Hardware Acceleration"
            ;;
        "4")
            run_setup_phase 4 "04_gpu_compute_stack.sh" "GPU / Compute Stack"
            ;;
        "5")
            run_setup_phase 5 "05_virtualization_passthrough.sh" "Virtualization & GPU Passthrough"
            ;;
        "6")
            run_setup_phase 6 "06_docker_development.sh" "Docker & Development"
            ;;
        "7")
            run_setup_phase 7 "07_developer_qol.sh" "Developer Quality of Life"
            ;;
        "8")
            run_setup_phase 8 "08_backup_resilience.sh" "Backup & Resilience"
            ;;
        *)
            error "Invalid phase specified: $phases_to_run"
            show_usage
            exit 1
            ;;
    esac
}

# Post-setup summary
post_setup_summary() {
    log "=== Setup Summary ==="
    
    info "Checking installed components..."
    
    # Network
    info "Network: $(ip addr show | grep -E "inet.*192\.|inet.*10\.|inet.*172\." | wc -l) active interfaces"
    
    # Security
    info "UFW Status: $(sudo ufw status | head -1)"
    info "Fail2ban: $(systemctl is-active fail2ban)"
    
    # Performance
    info "Tuned Profile: $(tuned-adm active 2>/dev/null || echo 'Not configured')"
    
    # GPU
    info "GPU Drivers: $(lsmod | grep amdgpu | wc -l) AMD GPU modules loaded"
    
    # Virtualization
    info "KVM: $(systemctl is-active libvirtd)"
    
    # Docker
    info "Docker: $(docker --version 2>/dev/null || echo 'Not available')"
    
    # Development
    info "VS Code: $(code --version 2>/dev/null | head -1 || echo 'Not available')"
    info "Shell: $SHELL"
    
    # Backup
    info "Timeshift: $(timeshift --version 2>/dev/null || echo 'Not available')"
    
    log "=== Next Steps ==="
    warning "IMPORTANT: A reboot is recommended to ensure all changes take effect"
    info "1. Reboot the system: sudo reboot"
    info "2. Test network connectivity and GPU drivers"
    info "3. Configure GitHub CLI: gh auth login"
    info "4. Create first backup: ./scripts/system_backup.sh full"
    info "5. Review logs: $LOG_FILE"
    
    log "Setup completed at $(date)"
}

# Usage information
show_usage() {
    echo "Usage: $0 [phase]"
    echo ""
    echo "Phases:"
    echo "  all (default) - Run all setup phases"
    echo "  1 - Networking & Drivers"
    echo "  2 - Security Hardening" 
    echo "  3 - Performance & Hardware Acceleration"
    echo "  4 - GPU / Compute Stack"
    echo "  5 - Virtualization & GPU Passthrough"
    echo "  6 - Docker & Development"
    echo "  7 - Developer Quality of Life"
    echo "  8 - Backup & Resilience"
    echo ""
    echo "Examples:"
    echo "  $0        # Run all phases"
    echo "  $0 all    # Run all phases"
    echo "  $0 1      # Run only networking setup"
    echo "  $0 4      # Run only GPU setup"
}

# Main execution
main() {
    # Handle help
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_usage
        exit 0
    fi
    
    # Initialize log file
    echo "=== Ubuntu 24.04.3 Enhanced Setup Log ===" > "$LOG_FILE"
    
    # Run setup
    check_privileges
    pre_flight_check
    make_executable
    main_setup "$1"
    post_setup_summary
    
    log "All done! Check the log file: $LOG_FILE"
}

# Run main function with all arguments
main "$@"
