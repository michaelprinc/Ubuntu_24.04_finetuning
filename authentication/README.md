# Authentication Configuration

This folder contains scripts for biometric and advanced authentication methods for Ubuntu 24.04.

## Scripts

- **`select_camera.sh`** - Interactive camera selection tool with preview
- **`setup_howdy.sh`** - Install and configure Howdy facial recognition authentication
- **`howdy_manage.sh`** - Comprehensive Howdy management (enable/disable/configure)
- **`howdy_rollback.sh`** - Complete removal and rollback of Howdy

## Usage

### Select Camera (Recommended First Step)

```bash
# Interactive camera selection with preview
./select_camera.sh
```

### Install Howdy (Facial Recognition)

```bash
# Install and setup facial recognition
./setup_howdy.sh
```

### Manage Howdy

```bash
# Check Howdy status
./howdy_manage.sh status

# Enable facial recognition
./howdy_manage.sh enable

# Disable facial recognition (keeps installation)
./howdy_manage.sh disable

# Add face model
./howdy_manage.sh add

# Test face detection
./howdy_manage.sh test

# Configure Howdy settings
./howdy_manage.sh config

# Show help
./howdy_manage.sh help
```

### Complete Rollback

```bash
# Completely remove Howdy and restore original authentication
./howdy_rollback.sh
```

## Features

### Camera Selection Tool
- Interactive camera testing with live preview
- Multiple camera support with easy switching
- Camera capability detection and recommendations
- Automatic configuration update with selected camera
- Manual camera specification option

### Howdy Facial Recognition
- Windows Hello style facial authentication
- Works with sudo, su, and PAM-enabled applications
- Support for both IR and regular webcams
- Multiple face models per user
- Configurable sensitivity and timeout settings

### Management Capabilities
- Easy enable/disable without reinstallation
- Safe PAM configuration backup and restore
- Face model management (add/remove)
- Comprehensive testing and validation
- Configuration editing interface

### Security Features
- Automatic PAM backup before changes
- Safe rollback procedures
- Verification of webcam availability
- Warning about security implications
- Support for fallback to password authentication

## Requirements

- Ubuntu 24.04.3 LTS
- Webcam (preferably IR camera for better security)
- Root/sudo access
- Python 3 and OpenCV support

## Security Considerations

### Advantages
- Convenient hands-free authentication
- Faster than typing passwords
- Works well in good lighting conditions
- Can be combined with password authentication

### Limitations
- Less secure than passwords alone
- Requires good lighting
- Regular webcams can potentially be spoofed
- May not work with glasses/facial changes
- Dependent on webcam functionality

### Best Practices
- Use with IR cameras when possible
- Keep password authentication as backup
- Be aware of lighting requirements
- Consider using for convenience, not critical security
- Regularly test functionality

## Troubleshooting

### Common Issues

**Webcam not detected:**
```bash
# Check for webcams
ls /dev/video*

# Test webcam
fswebcam test.jpg
```

**PAM authentication issues:**
```bash
# Check PAM configuration
cat /etc/pam.d/sudo

# Restore from backup
sudo cp /etc/pam.d/sudo.howdy-backup /etc/pam.d/sudo
```

**Face detection fails:**
```bash
# Test face detection
sudo howdy test

# Adjust lighting and camera angle
# Edit sensitivity in configuration
sudo howdy config
```

### Recovery

If authentication breaks:
1. Use recovery mode or another terminal
2. Run `./howdy_rollback.sh` to restore original authentication
3. Check PAM configuration files in `/etc/pam.d/`
4. Restore from backup files (`*.howdy-backup`)

## Configuration Files

- Main config: `/lib/security/howdy/config.ini`
- Face models: `/lib/security/howdy/models/`
- PAM configs: `/etc/pam.d/sudo`, `/etc/pam.d/su`
- Backups: `/etc/pam.d/*.howdy-backup`

## Notes

- Howdy works best with IR cameras (Windows Hello compatible)
- Regular webcams work but may be less secure
- Always keep password authentication available as backup
- Test thoroughly before relying on facial recognition
- Consider this a convenience feature, not primary security
