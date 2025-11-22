# Network Settings Reader Script

## Overview

`read-network-settings.sh` is a shell script that reads and displays current network settings from an Android system based on the configuration defined in `android-network-keys.json`. This is the complementary tool to `apply-network-defaults.sh`, allowing you to view current values before or after applying changes.

## Features

- **System Properties**: Reads Android system properties using `getprop`
- **Kernel Parameters**: Reads kernel networking parameters from `/proc/sys/net/`
- **Environment Variables**: Reads environment variables for network configuration
- **Android Settings**: Reads Android Settings database entries using the `settings` command
- **Multiple Output Formats**: Support for JSON, table, and compact formats
- **Category Filtering**: View settings for specific categories only
- **Default Comparison**: Compare current values against documented defaults
- **Verbose Logging**: Detailed output of all operations

## Requirements

### System Requirements
- Android system or Linux system with Android networking tools
- Standard POSIX tools (awk, sed, grep) - available by default on Android
- `json-parser.sh` - included JSON parser library (no external dependencies)

### Optional Tools
- `getprop` - For reading system properties (Android)
- `settings` - For reading Android Settings database (Android)

## Installation

1. Ensure the scripts are executable:
   ```bash
   chmod +x read-network-settings.sh json-parser.sh
   ```

2. Ensure both `read-network-settings.sh` and `json-parser.sh` are in the same directory.

3. Ensure the `android-network-keys.json` configuration file is in the same directory as the script (or specify a custom path with `-f`).

## Usage

### Basic Usage

```bash
# Read all network settings in table format (default)
./read-network-settings.sh

# Read settings in JSON format
./read-network-settings.sh -o json

# Read settings in compact format
./read-network-settings.sh -o compact

# Enable verbose output
./read-network-settings.sh -v
```

### Category Filtering

```bash
# Read only WiFi-related settings
./read-network-settings.sh -c wifi

# Read only DNS-related settings
./read-network-settings.sh -c dns

# Read only proxy settings
./read-network-settings.sh -c proxy
```

### Comparing with Defaults

```bash
# Compare current values with defaults (table format)
./read-network-settings.sh -s

# Compare current values with defaults (JSON format)
./read-network-settings.sh -s -o json

# Compare specific category with defaults
./read-network-settings.sh -c wifi -s
```

### Using a Custom Configuration File

```bash
./read-network-settings.sh -f /path/to/custom-config.json
```

### Command-Line Options

| Option | Description |
|--------|-------------|
| `-f, --file <path>` | Path to JSON configuration file (default: `android-network-keys.json`) |
| `-o, --output <format>` | Output format: json, table, or compact (default: `table`) |
| `-c, --category <category>` | Filter by specific category (e.g., wifi, dns, proxy) |
| `-s, --compare-defaults` | Compare current values against defaults |
| `-v, --verbose` | Enable verbose output showing all operations |
| `-h, --help` | Display help message |

## Output Formats

### Table Format (Default)

The table format provides a human-readable view of network settings organized by category:

```bash
./read-network-settings.sh -c wifi
```

Output:
```
========================================
System Properties - wifi
========================================
Key                                                | Current Value                                     
---------------------------------------------------+---------------------------------------------------
wifi.interface                                     | wlan0                                             
wifi.supplicant_scan_interval                      | 15                                                
wifi.direct.interface                              | p2p0                                              
persist.sys.wifi.only                              | 0                                                 
ro.wifi.channels                                   | 1-11                                              
```

### Table Format with Default Comparison

When using the `-s` flag, the table shows current values, default values, and whether they match:

```bash
./read-network-settings.sh -c wifi -s
```

Output:
```
========================================
System Properties - wifi
========================================
Key                                                | Current Value                  | Default Value                  | Match
---------------------------------------------------+--------------------------------+--------------------------------+------
wifi.interface                                     | wlan0                          | wlan0                          | ✓
wifi.supplicant_scan_interval                      | 30                             | 15                             | ✗
wifi.direct.interface                              | p2p0                           | p2p0                           | ✓
persist.sys.wifi.only                              | 0                              | 0                              | ✓
ro.wifi.channels                                   | 1-13                           | 1-11                           | ✗
```

### JSON Format

The JSON format provides machine-readable output suitable for parsing and automation:

```bash
./read-network-settings.sh -c wifi -o json
```

Output:
```json
{
  "timestamp": "2025-11-22T06:30:00Z",
  "network_settings": {
    "system_property_wifi": {
      "wifi.interface": {
        "current": "wlan0",
        "default": "wlan0",
        "description": "WiFi network interface name"
      },
      "wifi.supplicant_scan_interval": {
        "current": "15",
        "default": "15",
        "description": "Supplicant scan interval in seconds"
      }
    }
  }
}
```

With default comparison enabled (`-s`):
```json
{
  "timestamp": "2025-11-22T06:30:00Z",
  "network_settings": {
    "system_property_wifi": {
      "wifi.interface": {
        "current": "wlan0",
        "default": "wlan0",
        "description": "WiFi network interface name",
        "matches_default": true
      },
      "wifi.supplicant_scan_interval": {
        "current": "30",
        "default": "15",
        "description": "Supplicant scan interval in seconds",
        "matches_default": false
      }
    }
  }
}
```

### Compact Format

The compact format provides a concise view suitable for quick inspection or scripting:

```bash
./read-network-settings.sh -c wifi -o compact
```

Output:
```
wifi.interface=wlan0
wifi.supplicant_scan_interval=15
wifi.direct.interface=p2p0
persist.sys.wifi.only=0
ro.wifi.channels=1-11
```

With default comparison enabled (`-s`):
```
✓ wifi.interface=wlan0
✗ wifi.supplicant_scan_interval=30 (default: 15)
✓ wifi.direct.interface=p2p0
✓ persist.sys.wifi.only=0
✗ ro.wifi.channels=1-13 (default: 1-11)
```

## Configuration File Format

The script reads configuration from the same JSON file used by `apply-network-defaults.sh`:

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

## Use Cases

### Network Debugging

View current network configuration to diagnose issues:

```bash
# View all network settings
./read-network-settings.sh

# Check specific category (e.g., WiFi issues)
./read-network-settings.sh -c wifi -s

# Export to JSON for analysis
./read-network-settings.sh -o json > current-network-state.json
```

### Before/After Configuration Changes

Capture network state before and after applying changes:

```bash
# Capture current state
./read-network-settings.sh -o json > before.json

# Apply changes
./apply-network-defaults.sh -v

# Capture new state
./read-network-settings.sh -o json > after.json

# Compare
diff before.json after.json
```

### Configuration Auditing

Compare current settings against documented defaults:

```bash
# Check all settings against defaults
./read-network-settings.sh -s

# Check specific category
./read-network-settings.sh -c wifi -s

# Export differences for review
./read-network-settings.sh -s -o json | jq '.network_settings | .. | select(.matches_default? == false)'
```

### Automation and Scripting

Use in automated workflows:

```bash
# Check if WiFi interface is configured correctly
wifi_interface=$(./read-network-settings.sh -c wifi -o compact | grep wifi.interface | cut -d= -f2)
if [ "$wifi_interface" != "wlan0" ]; then
    echo "WiFi interface misconfigured!"
fi

# Monitor settings changes
while true; do
    ./read-network-settings.sh -o json > /tmp/current-state.json
    # Process and compare...
    sleep 60
done
```

## Behavior

### System Properties

The script uses `getprop` to read Android system properties. If `getprop` is not available (e.g., on non-Android Linux), the values will be empty.

Example:
```bash
getprop wifi.interface
```

### Kernel Parameters

The script reads kernel parameters directly from `/proc/sys/net/` files.

Example:
```bash
cat /proc/sys/net/ipv4/tcp_syncookies
```

### Environment Variables

The script reads environment variables from the current shell environment.

Example:
```bash
echo $HOSTNAME
```

### Android Settings

The script uses the `settings` command to read Android Settings database entries. If `settings` is not available (e.g., on non-Android Linux), the values will be empty.

Example:
```bash
settings get global airplane_mode_on
```

## Permissions

Different operations require different permission levels:

| Operation | Required Permission |
|-----------|-------------------|
| System Properties (read) | User or root |
| Kernel Parameters (read) | User (if file is readable) |
| Environment Variables (read) | User |
| Android Settings (read) | User or root (depending on namespace) |

Most read operations don't require root, but some settings or properties may require elevated permissions.

## Error Handling

The script handles errors gracefully:

- **Missing Tools**: If `getprop` or `settings` commands are unavailable, those values will be empty
- **Permission Denied**: If insufficient permissions to read a setting, the value will be empty
- **Missing Files**: If kernel parameter paths don't exist, the value will be empty

The script continues reading other settings even if some fail.

## Examples

### Example 1: Quick Check of All Settings

```bash
./read-network-settings.sh -o compact
```

### Example 2: Detailed WiFi Configuration Review

```bash
./read-network-settings.sh -c wifi -s -v
```

Output:
```
[INFO] ==========================================
[INFO] Android Network Settings Reader
[INFO] ==========================================
[INFO] Configuration file: android-network-keys.json
[INFO] Category filter: wifi
[INFO] Comparing with default values
[INFO] Verbose mode enabled

[VERBOSE] Checking requirements...
[VERBOSE] All requirements satisfied
[VERBOSE] Reading system properties...
[VERBOSE] Processing category: wifi

========================================
System Properties - wifi
========================================
Key                                                | Current Value                  | Default Value                  | Match
---------------------------------------------------+--------------------------------+--------------------------------+------
wifi.interface                                     | wlan0                          | wlan0                          | ✓
wifi.supplicant_scan_interval                      | 30                             | 15                             | ✗
wifi.direct.interface                              | p2p0                           | p2p0                           | ✓
persist.sys.wifi.only                              | 0                              | 0                              | ✓
ro.wifi.channels                                   | 1-13                           | 1-11                           | ✗

[INFO] ==========================================
[INFO] Reading complete
[INFO] ==========================================
```

### Example 3: Export Configuration for Documentation

```bash
# On Android device via ADB
adb push read-network-settings.sh /data/local/tmp/
adb push android-network-keys.json /data/local/tmp/
adb shell
cd /data/local/tmp
./read-network-settings.sh -o json > /sdcard/network-config-backup.json
```

### Example 4: Compare Multiple Categories

```bash
# Check WiFi settings
./read-network-settings.sh -c wifi -s

# Check proxy settings
./read-network-settings.sh -c proxy -s

# Check DNS settings
./read-network-settings.sh -c dns -s
```

## Troubleshooting

### "Required tools not found"

The script requires standard POSIX tools (awk, sed, grep) which should be available by default on Android. If you get this error on a non-Android Linux system, install the missing tools using your package manager.

### "json-parser.sh not found"

Ensure both `read-network-settings.sh` and `json-parser.sh` are in the same directory. Both files are required for the script to work.

### Empty Values for System Properties

If you see empty values for system properties, this might be because:
- The script is running on a non-Android system (no `getprop` command)
- The properties are not set on the device
- Insufficient permissions to read certain properties

### "Configuration file not found"

Ensure `android-network-keys.json` is in the same directory as the script, or use the `-f` option to specify the path:
```bash
./read-network-settings.sh -f /path/to/android-network-keys.json
```

## Integration with Apply Script

This script is designed to work alongside `apply-network-defaults.sh`:

### Workflow 1: Verify Before Applying

```bash
# Check current state
./read-network-settings.sh -s

# Apply defaults where needed
./apply-network-defaults.sh -v

# Verify changes
./read-network-settings.sh -s
```

### Workflow 2: Backup and Restore

```bash
# Backup current settings
./read-network-settings.sh -o json > backup.json

# Apply changes (if something goes wrong)
./apply-network-defaults.sh

# Compare against backup
./read-network-settings.sh -o json | diff backup.json -
```

## Development

### Adding New Configuration Types

To add support for new configuration types:

1. Add a new reading function (e.g., `read_new_type()`)
2. Add a processing function (e.g., `process_new_type()`)
3. Call the processing function from `main()`

### Testing

Test the script with different options:
```bash
# Test basic functionality
./read-network-settings.sh -h

# Test with different formats
./read-network-settings.sh -o json
./read-network-settings.sh -o table
./read-network-settings.sh -o compact

# Test with categories
./read-network-settings.sh -c wifi
./read-network-settings.sh -c proxy

# Test with comparison
./read-network-settings.sh -s
```

## Security Considerations

- **Read-Only Operations**: The script only reads settings, it doesn't modify anything
- **Configuration Validation**: Ensure the JSON configuration file comes from a trusted source
- **Sensitive Information**: Be careful when sharing output as it may contain sensitive network configuration
- **Log Files**: If redirecting output to files, protect them appropriately

## Contributing

Contributions are welcome! Please ensure:

- The script remains POSIX-compliant where possible
- Error handling is comprehensive
- Changes are tested with different output formats
- Documentation is updated accordingly

## License

GNU General Public License v3.0 (GPLv3) - See LICENSE file for details.

## Related Files

- `apply-network-defaults.sh` - Script to apply default network settings
- `android-network-keys.json` - Network configuration keys and defaults
- `NETWORK_KEYS.md` - Human-readable documentation of network keys
- `SCRIPT_README.md` - Documentation for the apply defaults script
- `README.md` - Main repository README

## Support

For issues, questions, or contributions, please refer to the main repository documentation.
