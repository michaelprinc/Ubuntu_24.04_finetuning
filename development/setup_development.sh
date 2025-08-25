#!/bin/bash

# Ubuntu 24.04.3 Developer Quality of Life Setup
# Implements VS Code, GitHub CLI, Zsh, and productivity tools

set -e

echo "=== 7. Developer Quality of Life Setup ==="

# Update package list
sudo apt update

# Install VS Code via snap (most reliable method)
if command -v code >/dev/null 2>&1; then
    echo "VS Code is already installed"
    code --version
else
    echo "Installing VS Code..."
    sudo snap install code --classic
fi

# Install GitHub CLI
if command -v gh >/dev/null 2>&1; then
    echo "GitHub CLI is already installed"
    gh --version
else
    echo "Installing GitHub CLI..."
    
    # Add GitHub CLI repository
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install -y gh
fi

# Install Zsh and Oh My Zsh (shell change disabled for stability)
echo "Installing Zsh and Oh My Zsh..."
sudo apt install -y zsh

# Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Note: Shell change disabled due to segfault issues
echo "Note: Zsh installed but shell change skipped for stability"
echo "To manually change shell later: sudo chsh -s /usr/bin/zsh $USER"

# Install productivity tools
echo "Installing productivity tools..."
sudo apt install -y \
    htop \
    btop \
    bat \
    exa \
    fd-find \
    ripgrep \
    tree \
    curl \
    wget \
    git \
    vim \
    neovim \
    tmux \
    jq \
    unzip \
    zip \
    ncdu \
    duf \
    tldr

# Install modern alternatives via snap
sudo snap install lsd

# Create aliases for better command line experience
echo "Creating useful aliases..."
tee ~/.bash_aliases > /dev/null << 'EOF'
# Modern CLI tools aliases
alias ll='exa -la --icons'
alias la='exa -a --icons'
alias ls='exa --icons'
alias lt='exa --tree --icons'
alias cat='batcat'
alias find='fd'
alias grep='rg'
alias du='duf'
alias df='duf'
alias top='btop'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph'
alias gd='git diff'

# Docker aliases
alias dc='docker-compose'
alias dps='docker ps'
alias di='docker images'
alias dlog='docker logs'

# System aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias mkdir='mkdir -p'
alias h='history'
alias c='clear'
alias reload='source ~/.bashrc'

# Development aliases
alias python='python3'
alias pip='pip3'
alias serve='python3 -m http.server'
EOF

# Configure Zsh with Oh My Zsh
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "Configuring Zsh with Oh My Zsh..."
    
    # Backup existing .zshrc
    cp ~/.zshrc ~/.zshrc.backup 2>/dev/null || true
    
    # Create enhanced .zshrc
    tee ~/.zshrc > /dev/null << 'EOF'
# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="robbyrussell"

# Plugins
plugins=(
    git
    docker
    docker-compose
    sudo
    zsh-autosuggestions
    zsh-syntax-highlighting
    history-substring-search
)

source $ZSH/oh-my-zsh.sh

# User configuration
export EDITOR='vim'
export LANG=en_US.UTF-8

# Load aliases
if [ -f ~/.bash_aliases ]; then
    source ~/.bash_aliases
fi

# Modern CLI tools
alias ll='exa -la --icons'
alias la='exa -a --icons'
alias ls='exa --icons'
alias lt='exa --tree --icons'
alias cat='batcat'
alias find='fd'
alias grep='rg'
alias du='duf'
alias df='duf'
alias top='btop'

# Development paths
export PATH="$HOME/.local/bin:$PATH"
export PATH="/opt/rocm/bin:$PATH"

# History configuration
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
EOF

    # Install Zsh plugins
    echo "Installing Zsh plugins..."
    
    # zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 2>/dev/null || true
    
    # zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 2>/dev/null || true
fi

# Configure Git (basic setup)
echo "Configuring Git..."
if [ -z "$(git config --global user.name)" ]; then
    echo "Git user not configured. Please run:"
    echo "git config --global user.name 'Your Name'"
    echo "git config --global user.email 'your.email@example.com'"
fi

# Set some useful Git defaults
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.editor vim

# Create VS Code workspace configuration
echo "Creating VS Code workspace configuration..."
mkdir -p /media/michael-princ/E85AE8F65AE8C284/Data_science_projects/Ubuntu_24.04_fine_tuning/.vscode

tee /media/michael-princ/E85AE8F65AE8C284/Data_science_projects/Ubuntu_24.04_fine_tuning/.vscode/settings.json > /dev/null << 'EOF'
{
    "terminal.integrated.defaultProfile.linux": "zsh",
    "python.defaultInterpreterPath": "/usr/bin/python3",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
        "source.organizeImports": "explicit"
    },
    "files.associations": {
        "*.sh": "shellscript"
    },
    "shellcheck.enable": true,
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": true,
    "git.autofetch": true,
    "extensions.autoUpdate": true
}
EOF

# Create recommended extensions list
tee /media/michael-princ/E85AE8F65AE8C284/Data_science_projects/Ubuntu_24.04_fine_tuning/.vscode/extensions.json > /dev/null << 'EOF'
{
    "recommendations": [
        "ms-python.python",
        "ms-python.pylint",
        "ms-toolsai.jupyter",
        "ms-vscode.docker",
        "timonwong.shellcheck",
        "eamodio.gitlens",
        "github.copilot",
        "ms-vscode-remote.remote-containers",
        "formulahendry.code-runner",
        "ms-vscode.theme-github-plus",
        "bradlc.vscode-tailwindcss",
        "esbenp.prettier-vscode"
    ]
}
EOF

# Development environment utilities are available in this directory

echo "=== Quality of Life Status ==="
echo "VS Code: $(code --version 2>/dev/null | head -1 || echo 'Not available in current session')"
echo "GitHub CLI: $(gh --version 2>/dev/null | head -1 || echo 'Not available')"
echo "Current shell: $SHELL"
echo "Zsh configuration: $([ -f ~/.zshrc ] && echo 'Configured' || echo 'Not configured')"

echo ""
echo "Installed productivity tools:"
which exa bat fd rg btop htop 2>/dev/null || echo "Some tools may need session restart"

echo "=== Developer Quality of Life Setup Complete ==="
echo "Next steps:"
echo "1. Log out and back in (or restart) for shell changes to take effect"
echo "2. Configure GitHub CLI: gh auth login"
echo "3. Configure Git with your credentials"
echo "4. Open VS Code and install recommended extensions"
echo "5. Use 'dev_env.sh status' to check environment"
