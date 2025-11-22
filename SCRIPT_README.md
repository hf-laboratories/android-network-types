# Network Configuration Script

## Overview

`apply-network-defaults.sh` is a shell script that applies best-effort default networking settings to an Android system based on the configuration defined in `android-network-keys.json`.

## Features

- **System Properties**: Sets Android system properties using `setprop`
- **Kernel Parameters**: Configures kernel networking parameters via `sysctl` or direct writes to `/proc/sys/net/`
- **Environment Variables**: Sets environment variables for network configuration
- **Android Settings**: Modifies Android Settings database entries using the `settings` command
- **Automatic Backup**: Creates backups before applying changes (first-run and pre-apply backups)
- **Dry-run Mode**: Preview changes without applying them
- **Verbose Logging**: Detailed output of all operations
- **Error Handling**: Graceful failure handling with informative messages

## Requirements

### System Requirements
- Android system or Linux system with Android networking tools
- Root or system-level permissions (for most operations)
- Standard POSIX tools (awk, sed, grep) - available by default on Android
- `json-parser.sh` - included JSON parser library (no external dependencies)

### Optional Tools
- `setprop` - For setting system properties (Android)
- `sysctl` - For setting kernel parameters
- `settings` - For modifying Android Settings database (Android)

## Installation

1. Ensure the scripts are executable:
   ```bash
   chmod +x apply-network-defaults.sh json-parser.sh
   ```

2. Ensure both `apply-network-defaults.sh` and `json-parser.sh` are in the same directory.

3. Ensure the `android-network-keys.json` configuration file is in the same directory as the script (or specify a custom path with `-f`).

## Usage

### Basic Usage

```bash
# Apply defaults (requires root permissions, will prompt for confirmation)
./apply-network-defaults.sh

# Skip confirmation prompt
./apply-network-defaults.sh -y

# Dry-run mode (preview without applying, no confirmation needed)
./apply-network-defaults.sh -d

# Verbose output
./apply-network-defaults.sh -v

# Combine options
./apply-network-defaults.sh -y -v
```

### Using a Custom Configuration File

```bash
./apply-network-defaults.sh -f /path/to/custom-config.json
```

### Command-Line Options

| Option | Description |
|--------|-------------|
| `-f, --file <path>` | Path to JSON configuration file (default: `android-network-keys.json`) |
| `-v, --verbose` | Enable verbose output showing all operations |
| `-d, --dry-run` | Show what would be applied without making changes (skips confirmation) |
| `-y, --yes` | Skip confirmation prompt and apply changes immediately |
| `-h, --help` | Display help message |

## Configuration File Format

The script reads configuration from a JSON file structured as follows:

```json
{
  "categories": {
    "system_properties": {
      "category_name": {
        "property.name": {
          "description": "Description of the property",
          "type": "string|integer|boolean",
          "example": "example_value",
          "default": "default_value"
        }
      }
    },
    "kernel_parameters": {
      "category_name": {
        "/proc/sys/net/path/to/parameter": {
          "description": "Description of the parameter",
          "type": "string|integer|boolean",
          "example": "example_value",
          "default": "default_value"
        }
      }
    },
    "environment_variables": {
      "category_name": {
        "VARIABLE_NAME": {
          "description": "Description of the variable",
          "type": "string",
          "example": "example_value",
          "default": "default_value"
        }
      }
    },
    "android_specific": {
      "settings": {
        "settings.namespace.key": {
          "description": "Description of the setting",
          "type": "string|integer|boolean",
          "example": "example_value",
          "default": "default_value"
        }
      }
    }
  }
}
```

### Important Notes

- Only properties with a `default` field will be applied
- Properties without a `default` field are skipped with a verbose message
- The `default` field should not be `null` or empty

## Behavior

### Automatic Backup

Before applying any changes, the script automatically creates a backup of current network settings:

**First Run Behavior:**
- When the script is run for the first time (no `./backups/` directory exists or is empty)
- Creates a backup named "first-run" 
- Description: "Automatic backup on first run"
- This preserves the initial state of the system

**Subsequent Runs:**
- On all subsequent runs (when backups already exist)
- Creates a backup named "pre-apply"
- Description: "Automatic backup before applying defaults"
- This allows you to restore to the state before the last apply operation

**Backup Location:**
- All backups are stored in `./backups/` directory
- Each backup is tracked in `./backups/metadata.json`
- Backups are in JSON format and can be restored using `restore-network-settings.sh`

**Skipped:**
- Backups are skipped in dry-run mode (`-d` flag)
- If backup script is not available, a warning is shown but apply continues

Example backup metadata:
```json
{
  "version": "1.0",
  "backups": [
    {
      "name": "first-run",
      "file": "backup_first-run.json",
      "timestamp": "2025-11-22T07:00:00Z",
      "description": "Automatic backup on first run"
    },
    {
      "name": "pre-apply",
      "file": "backup_pre-apply.json",
      "timestamp": "2025-11-22T08:00:00Z",
      "description": "Automatic backup before applying defaults"
    }
  ]
}
```

### System Properties

The script uses `setprop` to set Android system properties. These properties are typically used by Android services and applications.

Example:
```bash
setprop net.dns1 8.8.8.8
```

### Kernel Parameters

The script attempts to set kernel parameters using:
1. `sysctl` command (preferred method)
2. Direct write to `/proc/sys/net/` files (fallback)

Example:
```bash
sysctl -w net.ipv4.tcp_syncookies=1
# or
echo 1 > /proc/sys/net/ipv4/tcp_syncookies
```

### Environment Variables

The script exports environment variables in the current shell session.

Example:
```bash
export HOSTNAME=localhost
```

**Note**: Environment variables only persist for the current shell session unless added to profile files.

### Android Settings

The script uses the `settings` command to modify Android Settings database entries.

Example:
```bash
settings put global airplane_mode_on 0
```

Supported namespaces:
- `global` - System-wide settings
- `system` - User-specific settings
- `secure` - Secure settings requiring special permissions

## Permissions

Different operations require different permission levels:

| Operation | Required Permission |
|-----------|-------------------|
| System Properties (read-only `ro.*`) | Cannot be modified |
| System Properties (persistent `persist.*`) | Root or system |
| System Properties (others) | Root or system |
| Kernel Parameters | Root |
| Environment Variables | Current user |
| Android Settings | Root or system |

## Error Handling

The script handles errors gracefully:

- **Missing Tools**: Warns if `setprop`, `sysctl`, or `settings` commands are unavailable
- **Permission Denied**: Warns if insufficient permissions to modify a setting
- **Read-only Properties**: Warns if attempting to modify read-only properties
- **Missing Files**: Warns if kernel parameter paths don't exist

Errors are logged but don't stop script execution, allowing partial configuration application.

## Examples

### Example 1: Dry-run with Verbose Output

```bash
./apply-network-defaults.sh -d -v
```

Output:
```
[INFO] ==========================================
[INFO] Android Network Defaults Configuration
[INFO] ==========================================
[INFO] Configuration file: android-network-keys.json
[WARN] Running in DRY-RUN mode - no changes will be made
[INFO] Verbose mode enabled

[INFO] Checking requirements...
[VERBOSE] All requirements satisfied

[INFO] Processing system properties...
[VERBOSE] Processing category: dns
[VERBOSE] Applying system property: net.dns1 = 8.8.8.8 (Primary DNS server)
[DRY-RUN] Would set property: net.dns1 = 8.8.8.8
...
```

### Example 2: Apply Configuration

```bash
# On Android device via ADB
adb push apply-network-defaults.sh /data/local/tmp/
adb push android-network-keys.json /data/local/tmp/
adb shell
su
cd /data/local/tmp
./apply-network-defaults.sh -v
```

### Example 3: Custom Configuration

```bash
# Create a minimal configuration
cat > my-config.json << 'EOF'
{
  "categories": {
    "system_properties": {
      "dns": {
        "net.dns1": {
          "description": "Primary DNS",
          "default": "1.1.1.1"
        }
      }
    }
  }
}
EOF

# Apply custom configuration
./apply-network-defaults.sh -f my-config.json -v
```

## Troubleshooting

### "Required tools not found"

The script requires standard POSIX tools (awk, sed, grep) which should be available by default on Android. If you get this error on a non-Android Linux system, install the missing tools using your package manager.

### "json-parser.sh not found"

Ensure both `apply-network-defaults.sh` and `json-parser.sh` are in the same directory. Both files are required for the script to work.

### "Failed to set property (may require root)"

Most network configuration changes require root permissions:
```bash
su
./apply-network-defaults.sh
```

### "setprop command not available"

The script is running on a non-Android system. The script can still process kernel parameters and environment variables.

### Color Output Not Working

Some terminals don't support ANSI color codes. The script will still work, but colors may appear as escape sequences.

## Development

### Adding New Configuration Types

To add support for new configuration types:

1. Add a new processing function (e.g., `process_new_category()`)
2. Add logic to read from the JSON structure
3. Add an apply function for the specific tool/command needed
4. Call the processing function from `main()`

### Testing

Always test changes in dry-run mode first:
```bash
./apply-network-defaults.sh -d -v
```

## Security Considerations

- **Root Access**: The script requires root/system permissions for most operations
- **Configuration Validation**: Ensure the JSON configuration file comes from a trusted source
- **System Stability**: Incorrect network settings can affect system connectivity and stability
- **Testing**: Always test in a non-production environment first
- **Backup**: Consider backing up existing configuration before applying changes

## Integration with Other Branches

This script is designed to work with the `android-network-keys.json` file. When default values are added to the JSON file in another branch/PR:

1. The script will automatically detect properties with `default` fields
2. Only properties with defaults will be applied
3. No script modifications are needed when defaults are added to the JSON

The script is forward-compatible with the JSON schema and will handle new categories and properties automatically.

## Contributing

Contributions are welcome! Please ensure:

- The script remains POSIX-compliant where possible
- Error handling is comprehensive
- Changes are tested in both dry-run and actual modes
- Documentation is updated accordingly

## License

Apache License 2.0 - See LICENSE file for details.

## Related Files

- `android-network-keys.json` - Network configuration keys and defaults
- `NETWORK_KEYS.md` - Human-readable documentation of network keys
- `README.md` - Main repository README

## Support

For issues, questions, or contributions, please refer to the main repository documentation.
