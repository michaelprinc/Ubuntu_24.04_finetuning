#!/bin/bash

# Ubuntu 24.04.3 Security Hardening
# Implements automatic updates, AppArmor, firewall, and fail2ban

set -e

echo "=== 2. Security Hardening Setup ==="

# Check current security status
echo "Checking current security status..."
sudo apt update

# Install and configure unattended-upgrades
echo "Setting up automatic security updates..."
sudo apt install -y unattended-upgrades apt-listchanges

# Configure unattended-upgrades
sudo tee /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};

Unattended-Upgrade::DevRelease "auto";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-WithUsers "false";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
EOF

sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
EOF

# Enable the service
sudo systemctl enable unattended-upgrades
sudo systemctl start unattended-upgrades

# Check AppArmor status
echo "Checking AppArmor status..."
sudo apt install -y apparmor-utils
sudo aa-status

# Install and configure UFW firewall
echo "Setting up UFW firewall..."
sudo apt install -y ufw

# Configure UFW rules
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (important!)
sudo ufw allow ssh
sudo ufw allow 22/tcp

# Allow common services (adjust as needed)
sudo ufw allow 80/tcp  # HTTP
sudo ufw allow 443/tcp # HTTPS

# Enable UFW
sudo ufw --force enable

# Install and configure fail2ban
echo "Setting up fail2ban..."
sudo apt install -y fail2ban

# Create fail2ban local configuration
sudo tee /etc/fail2ban/jail.local > /dev/null << 'EOF'
[DEFAULT]
bantime = 600
findtime = 600
maxretry = 5
backend = systemd

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = %(sshd_log)s
maxretry = 3
bantime = 3600
EOF

# Enable and start fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Show status
echo "=== Security Status ==="
echo "Unattended-upgrades status:"
sudo systemctl status unattended-upgrades --no-pager -l

echo ""
echo "UFW status:"
sudo ufw status verbose

echo ""
echo "Fail2ban status:"
sudo systemctl status fail2ban --no-pager -l

echo ""
echo "AppArmor profiles:"
sudo aa-status | head -20

echo "=== Security Hardening Complete ==="
