# Ubuntu Keyboard Shortcuts Reference for Windows Users

This guide shows Ubuntu keyboard shortcuts compared to Windows 11, plus unique Ubuntu shortcuts that will boost your productivity.

## 🖥️ Desktop & Window Management

| Action | Windows 11 | Ubuntu (GNOME) | Notes |
|--------|------------|----------------|-------|
| Show Desktop | `Win + D` | `Super + D` | Same concept, different key name |
| Lock Screen | `Win + L` | `Super + L` | Identical after customization |
| Open Run Dialog | `Win + R` | `Alt + F2` or `Super + R`* | *After customization |
| Show All Windows | `Win + Tab` | `Super + S` or `Alt + Tab` | Super+S shows overview |
| Switch Between Apps | `Alt + Tab` | `Alt + Tab` | Identical |
| Close Window | `Alt + F4` | `Alt + F4` | Identical |
| Minimize Window | `Win + Down` | `Super + H` | Different key |
| Maximize Window | `Win + Up` | `Super + Up` | Identical |
| Snap Window Left | `Win + Left` | `Super + Left` | Identical |
| Snap Window Right | `Win + Right` | `Super + Right` | Identical |

## 🚀 Ubuntu-Specific Productivity Shortcuts

### Terminal Access (Windows Users Will Love This)
| Action | Shortcut | Description |
|--------|----------|-------------|
| Open Terminal | `Ctrl + Alt + T` | Quick terminal access anywhere |
| Terminal in File Manager | `F4` | Opens terminal in current folder |
| Multiple Terminal Tabs | `Ctrl + Shift + T` | New tab in terminal |
| Switch Terminal Tabs | `Ctrl + PageUp/PageDown` | Navigate terminal tabs |

### Workspace Management (Better than Windows Virtual Desktops)
| Action | Shortcut | Description |
|--------|----------|-------------|
| Switch Workspace | `Super + PageUp/PageDown` | Move between virtual desktops |
| Move Window to Workspace | `Super + Shift + PageUp/PageDown` | Take window to another workspace |
| Show All Workspaces | `Super + S` | Overview of all workspaces |
| Create New Workspace | `Super + S` then `+` | Add workspace dynamically |

### File Management Superpowers
| Action | Shortcut | Description |
|--------|----------|-------------|
| Open File Manager | `Super + E` | Like Windows Explorer |
| Navigate Up | `Alt + Up` | Go to parent directory |
| Navigate Back | `Alt + Left` | Previous location |
| Navigate Forward | `Alt + Right` | Next location |
| Show Hidden Files | `Ctrl + H` | Toggle hidden file visibility |
| Open in Terminal | `F4` | Terminal in current location |
| Properties | `Alt + Enter` | File/folder properties |

## 🎯 Application & System Shortcuts

### Application Management
| Action | Windows 11 | Ubuntu | Notes |
|--------|------------|--------|-------|
| Open Activities | `Win` | `Super` | Shows app launcher |
| App Launcher | `Win + S` | `Super + A` | Search and launch apps |
| System Settings | `Win + I` | `Super + I`* | *After customization |
| Task Manager | `Ctrl + Shift + Esc` | `Ctrl + Alt + Del` or `gnome-system-monitor` | |
| Screenshots | `Win + Shift + S` | `Print Screen` or `Shift + Print Screen` | |

### System Controls
| Action | Shortcut | Description |
|--------|----------|-------------|
| Power Off Menu | `Ctrl + Alt + Del` | System shutdown options |
| Force Quit App | `Alt + F2` then `xkill` | Click on frozen window |
| Restart GNOME | `Alt + F2` then `r` | Restart desktop without logout |

## 📋 Text Editing & Selection

### Universal Text Shortcuts (Same as Windows)
| Action | Shortcut | Description |
|--------|----------|-------------|
| Copy | `Ctrl + C` | Copy selection |
| Paste | `Ctrl + V` | Paste clipboard |
| Cut | `Ctrl + X` | Cut selection |
| Undo | `Ctrl + Z` | Undo last action |
| Redo | `Ctrl + Shift + Z` or `Ctrl + Y` | Redo action |
| Select All | `Ctrl + A` | Select all text |
| Find | `Ctrl + F` | Search in document |
| Save | `Ctrl + S` | Save document |

### Advanced Text Selection
| Action | Shortcut | Description |
|--------|----------|-------------|
| Select Word | `Double-click` | Select entire word |
| Select Line | `Triple-click` | Select entire line |
| Select to End | `Shift + End` | Select to end of line |
| Select to Beginning | `Shift + Home` | Select to start of line |

## 🌟 Ubuntu Advantages for Windows Users

### 1. Multiple Clipboard Support
```bash
# Install clipboard manager
sudo apt install clipit

# Access clipboard history
Super + V (after setup)
```

### 2. Powerful Terminal Integration
```bash
# Copy path of current folder
pwd | xclip -selection clipboard

# Open any file with default app
xdg-open filename.pdf

# Quick system info
hostnamectl
```

### 3. Package Management Shortcuts
```bash
# Quick software installation
sudo apt install package-name

# Search for software
apt search "keyword"

# Update everything
sudo apt update && sudo apt upgrade
```

### 4. Window Snapping (Better than Windows)
| Action | Shortcut | Result |
|--------|----------|---------|
| Quarter Snap Top-Left | `Super + Left` then `Super + Up` | Top-left quarter |
| Quarter Snap Top-Right | `Super + Right` then `Super + Up` | Top-right quarter |
| Center Window | `Super + C`* | Center on screen (*custom) |

## 🛠️ Customizing Shortcuts

### Using GNOME Settings
1. Open Settings → Keyboard → Keyboard Shortcuts
2. Scroll through categories to find shortcuts
3. Click on shortcut to change it
4. Press new key combination

### Using Command Line
```bash
# Set custom shortcut for terminal
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"

gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'gnome-terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Super>t'
```

## 🎓 Pro Tips for Windows Users

### 1. The Super Key is Your Friend
- `Super` alone: Opens Activities (like Start menu)
- `Super + Type`: Instant app search and launch
- `Super + Number`: Launch/switch to app in position N on taskbar

### 2. Middle Mouse Button Magic
- Middle-click on link: Opens in new tab
- Middle-click on tab: Closes tab
- Middle-click on titlebar: Minimizes window

### 3. Alt Key Superpowers
- `Alt + Click`: Move window from anywhere
- `Alt + Right-click`: Resize window from anywhere
- `Alt + F10`: Toggle maximize

### 4. Terminal Power (Game Changer for Windows Users)
```bash
# Navigate faster
cd -          # Go to previous directory
cd ~          # Go to home directory
cd ..         # Go up one level

# File operations
ls -la        # List all files with details
cp -r src/ dest/  # Copy folder recursively
mv old.txt new.txt  # Rename/move file

# System monitoring
htop          # Better task manager
df -h         # Disk usage
free -h       # Memory usage
```

## 📚 Learning Resources

- **GNOME Help**: `F1` in most applications
- **Man Pages**: `man command-name` in terminal
- **Keyboard Shortcuts**: Settings → Keyboard → Shortcuts
- **Extension Settings**: Extensions app or website

## 🚀 Quick Setup Commands

```bash
# Make keyboard shortcuts more Windows-like
./gui-customization/setup_windows_shortcuts.sh

# Create desktop shortcuts for common apps
./gui-customization/create_desktop_icon.sh common

# Install clipboard manager
sudo apt install clipit

# Set up additional shortcuts
gnome-control-center keyboard
```

Remember: Ubuntu's keyboard shortcuts are designed for efficiency. Once you learn them, you'll find many tasks faster than in Windows!
