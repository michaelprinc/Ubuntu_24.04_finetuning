#!/bin/bash

# Shell Recovery Script
# Restores Ubuntu 24.04 standard bash configuration

set -e

echo "=== Ubuntu 24.04 Shell Recovery Script ==="
echo "This script restores standard bash configuration"
echo ""

# Backup current configuration
echo "Creating backups..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
cp ~/.bashrc ~/.bashrc.backup.$TIMESTAMP 2>/dev/null || true
cp ~/.bash_aliases ~/.bash_aliases.backup.$TIMESTAMP 2>/dev/null || true

# Set shell to bash
echo "Setting shell to bash..."
sudo chsh -s /bin/bash $USER

# Restore clean bashrc
echo "Restoring clean bashrc..."
cp ~/.bashrc.clean ~/.bashrc 2>/dev/null || {
    echo "Creating clean bashrc from Ubuntu default..."
    sudo cp /etc/skel/.bashrc ~/.bashrc
    sudo chown $USER:$USER ~/.bashrc
}

# Create safe aliases
echo "Creating safe aliases..."
tee ~/.bash_aliases > /dev/null << 'EOF'
# Ubuntu 24.04 safe aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
alias h='history'
alias c='clear'
alias reload='source ~/.bashrc'
alias python='python3'
alias pip='pip3'
EOF

# Verify shell files
echo "Verifying shell configuration..."
if grep -q "duplicate" /etc/shells 2>/dev/null; then
    echo "Cleaning /etc/shells..."
    sudo tee /etc/shells > /dev/null << 'SHELLS'
# /etc/shells: valid login shells
/bin/sh
/usr/bin/sh
/bin/bash
/usr/bin/bash
/bin/rbash
/usr/bin/rbash
/usr/bin/dash
/bin/zsh
/usr/bin/zsh
SHELLS
fi

# Verify chsh permissions
echo "Verifying chsh permissions..."
sudo chmod 4755 /usr/bin/chsh

echo ""
echo "=== Recovery Complete ==="
echo "Current shell: $(getent passwd $USER | cut -d: -f7)"
echo "Bash version: $(bash --version | head -1)"
echo "Configuration: Ubuntu 24.04 standard"
echo ""
echo "Please log out and log back in for changes to take full effect."
echo "Backups saved with timestamp: $TIMESTAMP"
