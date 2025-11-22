# android-network-types

A comprehensive collection of all property and environment configuration keys related to networking on Android Linux.

## Overview

This repository documents Android networking configuration keys including:
- System properties (`getprop` accessible)
- Environment variables
- Kernel parameters (`/proc/sys/net/`)
- Network interface files (`/sys/class/net/`)
- Android Settings database entries
- **Best-effort default values** for each configuration key to enable resetting to defaults

## Documentation

### Main Network Utilities

- **[NETWORK_KEYS.md](NETWORK_KEYS.md)** - Human-readable documentation with tables and usage examples
- **[android-network-keys.json](android-network-keys.json)** - Machine-readable JSON format
- **[json-parser.sh](json-parser.sh)** - POSIX-compliant JSON parser (no external dependencies)
- **[read-network-settings.sh](read-network-settings.sh)** - Shell script to read current network settings
- **[READ_SCRIPT_README.md](READ_SCRIPT_README.md)** - Documentation for the network settings reader script
- **[apply-network-defaults.sh](apply-network-defaults.sh)** - Shell script to apply default network settings
- **[SCRIPT_README.md](SCRIPT_README.md)** - Documentation for the network configuration script
- **[backup-network-settings.sh](backup-network-settings.sh)** - Shell script to backup current network settings
- **[restore-network-settings.sh](restore-network-settings.sh)** - Shell script to restore network settings from backup
- **[BACKUP_RESTORE_README.md](BACKUP_RESTORE_README.md)** - Documentation for backup and restore scripts

### Generic Configuration Utility (`/alt` directory)

- **[alt/generic-apply-settings.sh](alt/generic-apply-settings.sh)** - Generic utility for applying any system settings
- **[alt/template-config.json](alt/template-config.json)** - Template showing configuration format
- **[alt/example-config.json](alt/example-config.json)** - Example configuration file
- **[alt/README.md](alt/README.md)** - Documentation for the generic utility

The `/alt` directory contains a generic, open-ended configuration utility that works with arbitrary categories and key-value pairs, suitable for any system configuration needs beyond just networking.

## Quick Start

### Reading Current Network Settings

```bash
# Read ALL current network settings (default action)
adb push read-network-settings.sh /data/local/tmp/
adb push json-parser.sh /data/local/tmp/
adb push android-network-keys.json /data/local/tmp/
adb shell
cd /data/local/tmp
./read-network-settings.sh

# Read settings in JSON format
./read-network-settings.sh -o json

# Read specific category (e.g., WiFi)
./read-network-settings.sh -c wifi

# Compare current values with defaults
./read-network-settings.sh -s

# Compact output for quick overview
./read-network-settings.sh -o compact
```

For detailed usage of the reader script, see [READ_SCRIPT_README.md](READ_SCRIPT_README.md).

### Viewing Properties on Android

```bash
# View all properties
adb shell getprop

# View specific property
adb shell getprop wifi.interface

# View network-related properties
adb shell getprop | grep net
```

### Viewing Kernel Parameters

```bash
# View IPv4 settings
adb shell cat /proc/sys/net/ipv4/ip_forward

# View all network kernel parameters
adb shell ls -la /proc/sys/net/
```

### Applying Network Defaults

```bash
# Apply default settings to ALL network configurations (requires root, will prompt for confirmation)
adb push apply-network-defaults.sh /data/local/tmp/
adb push json-parser.sh /data/local/tmp/
adb push android-network-keys.json /data/local/tmp/
adb shell
su
cd /data/local/tmp
./apply-network-defaults.sh

# Skip confirmation prompt
./apply-network-defaults.sh -y

# Dry-run mode to preview changes (no confirmation needed)
./apply-network-defaults.sh -d

# Verbose output with confirmation skip
./apply-network-defaults.sh -y -v
```

For detailed usage of the configuration script, see [SCRIPT_README.md](SCRIPT_README.md).

### Backup and Restore Network Settings

```bash
# Create a backup of current network settings
adb push backup-network-settings.sh /data/local/tmp/
adb push read-network-settings.sh /data/local/tmp/
adb push json-parser.sh /data/local/tmp/
adb push android-network-keys.json /data/local/tmp/
adb shell
cd /data/local/tmp
./backup-network-settings.sh -n "pre-update" -d "Before system update"

# List available backups
./restore-network-settings.sh -l

# Restore from backup (requires root)
su
./restore-network-settings.sh -n "pre-update"
```

For detailed usage of backup and restore scripts, see [BACKUP_RESTORE_README.md](BACKUP_RESTORE_README.md).

### Using the Generic Configuration Utility

For applying any system settings beyond networking:

```bash
# Navigate to alt directory
cd alt

# Apply generic configuration with dry-run
./generic-apply-settings.sh -f template-config.json -d -v

# Apply custom configuration
./generic-apply-settings.sh -f myconfig.json -y

# Apply only specific category
./generic-apply-settings.sh -f myconfig.json -c system_properties
```

The generic utility supports open-ended categories and key-value pairs, making it suitable for any system configuration needs. See [alt/README.md](alt/README.md) for details.

## Categories

The collection is organized into the following categories:

1. **WiFi** - WiFi interface properties and configuration
2. **Mobile Data** - Cellular network properties (GSM, LTE, etc.)
3. **Network Interfaces** - Interface-specific settings and TCP buffer sizes
4. **Proxy** - HTTP/HTTPS proxy configuration
5. **VPN** - VPN-related properties
6. **Tethering** - USB/WiFi/Bluetooth tethering
7. **IPv6** - IPv6 configuration and settings
8. **DHCP** - DHCP client configuration
9. **Radio** - Radio interface layer (RIL) properties
10. **Connectivity** - General connectivity settings
11. **Kernel Parameters** - Linux kernel networking parameters
12. **Android Settings** - Android Settings database entries

## Use Cases

- **Reading current settings** - View and export current network configuration from Android devices
- **Backup and restore** - Save current network state and restore to previous configurations with metadata tracking
- **Network debugging** - Understanding current network configuration and comparing against defaults
- **Device development** - Configuring network settings for custom Android builds
- **Testing** - Simulating different network conditions and verifying changes, with ability to restore previous state
- **Documentation** - Reference for Android networking internals
- **Automation** - Scripting network configuration changes and monitoring
- **Reset to defaults** - Using provided default values to restore network settings to a known good state
- **Configuration auditing** - Compare current values against documented defaults to identify deviations
- **Safe experimentation** - Make changes with confidence knowing you can restore to a known good state

## Default Values

Each configuration key includes a `default` field in the JSON format that represents a best-effort default value. These defaults can be used to:

- **Restore network settings** to a baseline configuration
- **Initialize devices** with safe, commonly-used settings
- **Troubleshoot issues** by comparing current values against defaults
- **Automate configuration** in testing and development environments

Example from `android-network-keys.json`:
```json
{
  "wifi.interface": {
    "description": "WiFi network interface name",
    "type": "string",
    "example": "wlan0",
    "default": "wlan0"
  }
}
```

For more details, see the [Default Values section](NETWORK_KEYS.md#default-values) in the documentation.

## Contributing

Contributions are welcome! If you find additional network-related configuration keys, please:
1. Fork this repository
2. Add the keys to both `NETWORK_KEYS.md` and `android-network-keys.json`
3. Submit a pull request with a description of the keys added

## License

Apache License 2.0 - See [LICENSE](LICENSE) file for details.
