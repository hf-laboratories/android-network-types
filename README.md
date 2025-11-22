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

- **[NETWORK_KEYS.md](NETWORK_KEYS.md)** - Human-readable documentation with tables and usage examples
- **[android-network-keys.json](android-network-keys.json)** - Machine-readable JSON format

## Quick Start

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

- **Network debugging** - Understanding current network configuration
- **Device development** - Configuring network settings for custom Android builds
- **Testing** - Simulating different network conditions
- **Documentation** - Reference for Android networking internals
- **Automation** - Scripting network configuration changes
- **Reset to defaults** - Using provided default values to restore network settings to a known good state

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
