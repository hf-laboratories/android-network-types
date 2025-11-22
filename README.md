# android-network-types

A comprehensive collection of all property and environment configuration keys related to networking on Android Linux.

## Overview

This repository documents Android networking configuration keys including:
- System properties (`getprop` accessible)
- Environment variables
- Kernel parameters (`/proc/sys/net/`)
- Network interface files (`/sys/class/net/`)
- Android Settings database entries

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
3. **DNS** - DNS server configuration
4. **Network Interfaces** - Interface-specific settings and TCP buffer sizes
5. **Proxy** - HTTP/HTTPS proxy configuration
6. **VPN** - VPN-related properties
7. **Tethering** - USB/WiFi/Bluetooth tethering
8. **IPv6** - IPv6 configuration and settings
9. **DHCP** - DHCP client configuration
10. **Radio** - Radio interface layer (RIL) properties
11. **Connectivity** - General connectivity settings
12. **Routing** - Network routing configuration
13. **Kernel Parameters** - Linux kernel networking parameters
14. **Android Settings** - Android Settings database entries

## Use Cases

- **Network debugging** - Understanding current network configuration
- **Device development** - Configuring network settings for custom Android builds
- **Testing** - Simulating different network conditions
- **Documentation** - Reference for Android networking internals
- **Automation** - Scripting network configuration changes

## Contributing

Contributions are welcome! If you find additional network-related configuration keys, please:
1. Fork this repository
2. Add the keys to both `NETWORK_KEYS.md` and `android-network-keys.json`
3. Submit a pull request with a description of the keys added

## License

Apache License 2.0 - See [LICENSE](LICENSE) file for details.
