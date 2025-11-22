# Network Settings Backup and Restore Scripts

## Overview

The backup and restore scripts provide functionality to save and restore network settings on Android systems, with metadata tracking to manage multiple backup states.

## Scripts

### backup-network-settings.sh

Creates a backup of all current network settings in JSON format and tracks backups in a metadata file.

**Features:**
- Backs up all network-related system properties, kernel parameters, environment variables, and Android Settings
- Generates timestamped backup files or uses custom names
- Maintains metadata.json with backup history
- Supports custom backup directories and descriptions

### restore-network-settings.sh

Restores network settings from a previously created backup file.

**Features:**
- Lists available backups from metadata
- Restores settings by backup name or file path
- Interactive confirmation prompt (bypass with `-y`)
- Dry-run mode to preview changes
- Applies system properties, kernel parameters, environment variables, and Android Settings

## Usage

### Creating a Backup

```bash
# Create backup with auto-generated timestamp name
./backup-network-settings.sh

# Create backup with custom name and description
./backup-network-settings.sh -n "pre-update" -d "Before system update"

# Create backup in custom directory with verbose output
./backup-network-settings.sh -o /sdcard/backups -v

# Example on Android device via ADB
adb push backup-network-settings.sh /data/local/tmp/
adb push read-network-settings.sh /data/local/tmp/
adb push json-parser.sh /data/local/tmp/
adb push android-network-keys.json /data/local/tmp/
adb shell
cd /data/local/tmp
./backup-network-settings.sh -n "my-backup" -d "Custom backup"
```

### Listing Backups

```bash
# List all available backups
./restore-network-settings.sh -l

# Output shows:
# - Backup number
# - Backup name
# - Filename
# - Timestamp
# - Description
```

### Restoring from Backup

```bash
# List available backups first
./restore-network-settings.sh -l

# Restore specific backup by name (with confirmation prompt)
./restore-network-settings.sh -n "pre-update"

# Restore from specific file path
./restore-network-settings.sh -f ./backups/backup_20241122_063000.json

# Restore without confirmation (for automation)
./restore-network-settings.sh -n "pre-update" -y

# Dry-run to preview what would be restored
./restore-network-settings.sh -n "pre-update" -d -v

# Example on Android device via ADB (requires root)
adb push restore-network-settings.sh /data/local/tmp/
adb push json-parser.sh /data/local/tmp/
adb shell
su
cd /data/local/tmp
./restore-network-settings.sh -l
./restore-network-settings.sh -n "my-backup" -y
```

## Command-Line Options

### backup-network-settings.sh

| Option | Description |
|--------|-------------|
| `-o, --output <path>` | Output directory for backups (default: `./backups`) |
| `-n, --name <name>` | Custom backup name (default: auto-generated timestamp) |
| `-d, --description <text>` | Description for this backup |
| `-v, --verbose` | Enable verbose output |
| `-h, --help` | Display help message |

### restore-network-settings.sh

| Option | Description |
|--------|-------------|
| `-f, --file <path>` | Path to backup file to restore |
| `-l, --list` | List available backups |
| `-n, --name <name>` | Restore backup by name |
| `-b, --backup-dir <path>` | Backup directory (default: `./backups`) |
| `-y, --yes` | Skip confirmation prompt |
| `-d, --dry-run` | Show what would be restored without applying |
| `-v, --verbose` | Enable verbose output |
| `-h, --help` | Display help message |

## Backup File Structure

Backup files are JSON formatted and contain:
- Timestamp of backup creation
- All system properties with current values
- All kernel parameters with current values
- All environment variables with current values
- All Android Settings with current values

Example backup file structure:
```json
{
  "timestamp": "2025-11-22T07:00:00Z",
  "network_settings": {
    "system_property_wifi": {
      "wifi.interface": {
        "current": "wlan0",
        "default": "wlan0",
        "description": "WiFi network interface name"
      }
    },
    "kernel_parameter_net_sysctl": {
      "/proc/sys/net/ipv4/ip_forward": {
        "current": "0",
        "default": "0",
        "description": "Enable IP forwarding"
      }
    }
  }
}
```

## Metadata File

The `metadata.json` file tracks all backups and is automatically updated when creating backups.

Structure:
```json
{
  "version": "1.0",
  "backups": [
    {
      "name": "pre-update",
      "file": "backup_pre-update.json",
      "timestamp": "2025-11-22T07:00:00Z",
      "description": "Before system update",
      "created_by": "backup-network-settings.sh"
    }
  ]
}
```

## Workflow Examples

### Before Making Changes

```bash
# Create backup before applying defaults
./backup-network-settings.sh -n "pre-defaults" -d "Before applying defaults"

# Apply network defaults
./apply-network-defaults.sh -y -v

# If something goes wrong, restore previous state
./restore-network-settings.sh -n "pre-defaults" -y
```

### Regular Backups

```bash
# Create daily backup
./backup-network-settings.sh -d "Daily backup"

# List all backups
./restore-network-settings.sh -l

# Restore to any previous state
./restore-network-settings.sh -n "20241120_080000"
```

### Testing Configuration Changes

```bash
# Backup current state
./backup-network-settings.sh -n "before-test"

# Make configuration changes
# ... test changes ...

# If test fails, restore
./restore-network-settings.sh -n "before-test" -y

# If test succeeds, create new backup
./backup-network-settings.sh -n "after-test" -d "Successful test configuration"
```

## Requirements

### backup-network-settings.sh
- `read-network-settings.sh` in the same directory
- `json-parser.sh` in the same directory
- Standard POSIX tools (date, mkdir, cat)

### restore-network-settings.sh
- `json-parser.sh` in the same directory
- Root/system permissions (for applying settings)
- Standard POSIX tools available on Android

## Important Notes

### Permissions
- **Backup**: Does not require root (only reads settings)
- **Restore**: Requires root permissions to apply settings

### Environment Variables
Environment variables restored are session-specific and will not persist after the current shell session ends. To make them permanent, they need to be added to shell profile files.

### Read-only Properties
Some Android system properties (those starting with `ro.`) are read-only and cannot be changed after boot. The restore script will attempt to set them but may fail.

### Backup Storage
- Backups are stored in the specified directory (default: `./backups`)
- Each backup is a separate JSON file
- The metadata file tracks all backups
- Consider the storage space needed for multiple backups

## Troubleshooting

### "read-network-settings.sh not found"
Ensure all required scripts are in the same directory:
- `backup-network-settings.sh`
- `read-network-settings.sh`
- `json-parser.sh`
- `android-network-keys.json`

### "Failed to create backup directory"
Check write permissions for the backup directory location.

### "Backup not found with name: xxx"
Use `-l` to list available backups and verify the name.

### Settings not applying during restore
- Verify you have root permissions (`su`)
- Some settings require a reboot to take effect
- Some properties are read-only and cannot be changed

## Integration

These scripts integrate with the existing network configuration tools:

```bash
# Workflow: Backup → Modify → Restore if needed
./backup-network-settings.sh -n "safety"
./apply-network-defaults.sh -y
# Test network...
./restore-network-settings.sh -n "safety" -y  # If needed
```

## License

Apache License 2.0 - See LICENSE file for details.

## Related Files

- `read-network-settings.sh` - Reads current network settings
- `apply-network-defaults.sh` - Applies default network settings
- `json-parser.sh` - JSON parsing library
- `android-network-keys.json` - Network configuration keys
