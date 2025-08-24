# Ubuntu GUI Troubleshooting Guide for Windows Users

Common issues Windows users face when switching to Ubuntu and their solutions.

## 🖥️ Desktop & Interface Issues

### "I can't create desktop icons / Pin to Desktop is missing"

**Problem**: Ubuntu GNOME doesn't show desktop icons by default, and there's no "Pin to Desktop" option in right-click menus.

**Solutions**:
```bash
# Method 1: Install Desktop Icons NG extension
./gui-customization/setup_windows_like_gui.sh desktop

# Method 2: Use our desktop icon creator script
./gui-customization/create_desktop_icon.sh "Firefox"
./gui-customization/create_desktop_icon.sh common  # Creates common icons

# Method 3: Manual creation
cp /usr/share/applications/firefox.desktop ~/Desktop/
chmod +x ~/Desktop/firefox.desktop
gio set ~/Desktop/firefox.desktop metadata::trusted true
```

**Alternative**: Use the dock/taskbar - right-click on running apps and select "Add to Favorites"

### "Extension installation fails with 404 errors"

**Problem**: GNOME extension download URLs return 404 Not Found errors.

**Solutions**:
```bash
# Use our improved extension installer
./gui-customization/install_gnome_extensions.sh

# Or install Extension Manager and use GUI
sudo apt install gnome-shell-extension-manager
# Then open "Extensions" app and browse/install extensions

# Alternative: Install via Flatpak
flatpak install flathub com.mattjakeman.ExtensionManager

# Manual installation via browser:
# 1. Open Firefox/Chrome
# 2. Go to https://extensions.gnome.org
# 3. Install browser extension when prompted
# 4. Search and install: Dash to Panel, ArcMenu, Desktop Icons NG
```

**Root Cause**: GNOME extensions website changed their download URLs and version compatibility system. Our script now uses multiple installation methods as fallbacks.

### "Extensions don't work after installation"

**Problem**: Extensions are installed but don't appear or function.

**Solutions**:
```bash
# Check if extensions are installed
gnome-extensions list

# Enable extensions manually
gnome-extensions enable dash-to-panel@jderose9.github.com
gnome-extensions enable arcmenu@arcmenu.com
gnome-extensions enable ding@rastersoft.com

# Check GNOME version compatibility
gnome-shell --version

# Restart GNOME Shell (X11 only - doesn't work on Wayland)
Alt + F2, type 'r', press Enter

# For Wayland, log out and back in
```

### "Where is the Start Menu?"

**Problem**: Ubuntu uses Activities overview instead of a traditional Start menu.

**Solutions**:
```bash
# Install ArcMenu extension for Windows-like start menu
./gui-customization/setup_windows_like_gui.sh taskbar

# Or use existing interface:
# - Press Super key (Windows key)
# - Type application name
# - Press Enter
```

**Pro Tip**: The Super key + typing is often faster than navigating through menus!

### "The taskbar is on the side, not bottom"

**Problem**: Ubuntu's dock is on the left by default.

**Solutions**:
```bash
# Install Dash to Panel for bottom taskbar
./gui-customization/setup_windows_like_gui.sh taskbar

# Or move existing dock to bottom:
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position BOTTOM
```

## 🪟 Window Management Issues

### "I can't resize windows by dragging edges"

**Problem**: Window edges might be too thin or you're not dragging from the right spot.

**Solutions**:
- Drag from the very edge of the window (1-2 pixels)
- Hold `Super` key + right-click anywhere on window to resize
- Use keyboard: `Alt + F8` then arrow keys
- Double-click window title bar to maximize/restore

### "Windows don't snap properly"

**Problem**: Window snapping behaves differently than Windows 11.

**Solutions**:
```bash
# Ensure snapping is enabled
gsettings set org.gnome.mutter edge-tiling true

# Use keyboard shortcuts:
# Super + Left/Right for half-screen
# Super + Left then Super + Up for quarter-screen
```

### "Alt + Tab doesn't work the same"

**Problem**: Alt + Tab behavior differs from Windows.

**Solutions**:
```bash
# Make Alt+Tab switch between windows (not applications)
gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Super>Tab']"
```

## 📁 File Management Issues

### "I can't access Windows drives"

**Problem**: Windows NTFS drives might not mount automatically.

**Solutions**:
```bash
# Install NTFS support
sudo apt install ntfs-3g

# Mount Windows drive manually
sudo mkdir -p /mnt/windows
sudo mount -t ntfs-3g /dev/sdX1 /mnt/windows  # Replace sdX1 with your drive

# Auto-mount on startup - add to /etc/fstab:
echo "/dev/sdX1 /mnt/windows ntfs-3g defaults,uid=1000,gid=1000 0 0" | sudo tee -a /etc/fstab
```

### "File manager is too simple"

**Problem**: Default Files app lacks features compared to Windows Explorer.

**Solutions**:
```bash
# Install more feature-rich file managers
sudo apt install nemo thunar dolphin

# Set Nemo as default (most Windows-like)
./gui-customization/setup_windows_like_gui.sh

# Or manually:
xdg-mime default nemo.desktop inode/directory
```

### "Where are hidden files?"

**Problem**: Hidden files/folders are not visible by default.

**Solutions**:
- Press `Ctrl + H` in file manager to toggle hidden files
- Or: View menu → Show Hidden Files
- Or permanently: Edit → Preferences → Views → Show hidden files

## 🎨 Appearance Issues

### "Ubuntu looks nothing like Windows"

**Problem**: Default Ubuntu theme is very different from Windows 11.

**Solutions**:
```bash
# Install Windows 11-like theme
./gui-customization/setup_windows_like_gui.sh theme

# Or install manually:
# WhiteSur theme (Windows-like clean look)
# Fluent icons (Windows 11-style icons)
# Configure in GNOME Tweaks
```

### "Fonts look different/bad"

**Problem**: Font rendering differs from Windows.

**Solutions**:
```bash
# Install Windows fonts
sudo apt install ttf-mscorefonts-installer

# Install additional font packages
sudo apt install fonts-liberation fonts-liberation2

# Configure font rendering
gsettings set org.gnome.desktop.interface font-name 'Segoe UI 11'
```

## ⚙️ System Settings Issues

### "I can't find Control Panel"

**Problem**: Ubuntu uses Settings app instead of Control Panel.

**Solutions**:
- Press `Super + I` to open Settings
- Or: Click user menu (top right) → Settings
- For advanced settings: Install `gnome-tweaks` and `dconf-editor`

### "Where is Device Manager?"

**Problem**: Ubuntu doesn't have a direct equivalent to Device Manager.

**Solutions**:
```bash
# Hardware information
sudo lshw -short
lsusb        # USB devices
lspci        # PCI devices
lscpu        # CPU info

# GUI alternative
sudo apt install hardinfo
hardinfo     # Graphical hardware info
```

### "How do I install/uninstall software?"

**Problem**: No Add/Remove Programs like Windows.

**Solutions**:
```bash
# GUI method - Ubuntu Software Center
gnome-software

# GUI method - Synaptic (advanced)
sudo apt install synaptic

# Command line (fastest)
sudo apt install package-name    # Install
sudo apt remove package-name     # Uninstall
sudo apt search keyword          # Search

# Alternative package formats
sudo snap install package-name   # Snap packages
flatpak install package-name     # Flatpak packages
```

## 🌐 Network Issues

### "WiFi doesn't work"

**Problem**: Wireless drivers might not be installed.

**Solutions**:
```bash
# Check wireless status
nmcli device status

# Install additional drivers
sudo ubuntu-drivers autoinstall

# Or use GUI: Software & Updates → Additional Drivers
```

### "Ethernet is slow"

**Problem**: Ethernet driver issues (common with Realtek).

**Solutions**:
```bash
# Check if our script already handles this
./scripts/01_networking_drivers.sh

# Manual driver installation
sudo apt install r8168-dkms
```

## 🔧 Application Issues

### "My Windows software doesn't run"

**Problem**: Windows applications need compatibility layer or alternatives.

**Solutions**:
```bash
# Wine for Windows software
sudo apt install wine

# Alternative applications
# Microsoft Office → LibreOffice
# Photoshop → GIMP
# Notepad++ → VS Code or Gedit
# Windows Media Player → VLC
```

### "Applications don't start"

**Problem**: Missing dependencies or incorrect installation.

**Solutions**:
```bash
# Try starting from terminal to see error
application-name

# Check if installed correctly
which application-name
dpkg -l | grep application-name

# Reinstall if needed
sudo apt remove --purge application-name
sudo apt install application-name
```

## 🛠️ Performance Issues

### "Ubuntu feels slow"

**Problem**: Various performance issues.

**Solutions**:
```bash
# Check system resources
htop

# Disable unnecessary startup applications
gnome-session-properties

# Check for disk issues
sudo fsck /dev/sda1

# Run our performance optimization
./scripts/03_performance_tuning.sh
```

### "Too many animations"

**Problem**: Animations might feel sluggish on older hardware.

**Solutions**:
```bash
# Reduce animations
gsettings set org.gnome.desktop.interface enable-animations false

# Or use GNOME Tweaks to reduce animation speed
```

## 🚨 Emergency Recovery

### "Desktop doesn't load"

**Problem**: Display manager or desktop environment issues.

**Solutions**:
```bash
# Try different session at login screen
# Select gear icon → choose "Ubuntu on Xorg"

# Reset GNOME settings
dconf reset -f /org/gnome/

# Reinstall desktop environment
sudo apt install --reinstall ubuntu-desktop
```

### "System won't boot"

**Problem**: Boot issues after updates or changes.

**Solutions**:
```bash
# Boot from live USB
# Mount your Ubuntu partition
# Run our recovery script
./scripts/shell_recovery.sh
```

## 📋 Quick Fixes Checklist

When something doesn't work:

1. **Update system first**:
   ```bash
   sudo apt update && sudo apt upgrade
   ```

2. **Check if it's a known issue**:
   ```bash
   # Search for similar problems
   apt search problem-keyword
   ```

3. **Try the terminal**:
   ```bash
   # Run the application from terminal to see errors
   application-name
   ```

4. **Restart the service**:
   ```bash
   # For system services
   sudo systemctl restart service-name
   ```

5. **Log out and back in**:
   - Many GUI changes require a session restart

6. **Check logs**:
   ```bash
   journalctl -xe  # System logs
   dmesg          # Kernel messages
   ```

## 🆘 Getting Help

### Ubuntu Community Resources
- **Ask Ubuntu**: https://askubuntu.com/
- **Ubuntu Forums**: https://ubuntuforums.org/
- **Ubuntu Reddit**: r/Ubuntu

### Command Line Help
```bash
man command-name    # Manual pages
command-name --help # Command help
apropos keyword     # Find commands related to keyword
```

### System Information for Support
```bash
# Gather system info for support requests
sudo apt install neofetch
neofetch

# Or detailed info
lsb_release -a
uname -a
```

Remember: Ubuntu's community is very helpful! Don't hesitate to ask questions with specific error messages and system information.
