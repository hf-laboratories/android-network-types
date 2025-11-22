# Android Network Configuration Keys

A comprehensive collection of property keys, environment variables, and configuration paths related to networking on Android Linux.

## Table of Contents

- [System Properties](#system-properties)
  - [WiFi](#wifi)
  - [Mobile Data](#mobile-data)
  - [DNS](#dns)
  - [Network Interfaces](#network-interfaces)
  - [Proxy](#proxy)
  - [VPN](#vpn)
  - [Tethering](#tethering)
  - [IPv6](#ipv6)
  - [DHCP](#dhcp)
  - [Radio](#radio)
  - [Connectivity](#connectivity)
  - [Routing](#routing)
  - [NFC](#nfc)
  - [Bluetooth](#bluetooth)
- [Environment Variables](#environment-variables)
- [Kernel Parameters](#kernel-parameters)
- [Network Interface Files](#network-interface-files)
- [Android Settings](#android-settings)
- [Usage Notes](#usage-notes)

## System Properties

System properties can be accessed using the `getprop` command or the `android.os.SystemProperties` API.

### WiFi

| Property | Description | Type | Example |
|----------|-------------|------|---------|
| `wifi.interface` | WiFi network interface name | string | `wlan0` |
| `wifi.supplicant_scan_interval` | Supplicant scan interval in seconds | integer | `15` |
| `wifi.direct.interface` | WiFi Direct interface name | string | `p2p0` |
| `persist.sys.wifi.only` | Enable WiFi only mode | boolean | `1` |
| `ro.wifi.channels` | Available WiFi channels | string | `1-13` |

### Mobile Data

| Property | Description | Type | Example |
|----------|-------------|------|---------|
| `ro.telephony.default_network` | Default network type (LTE/3G/2G) | integer | `9` |
| `net.mobile.radio` | Mobile radio state | string | `on` |
| `net.lte.ims.data.enabled` | LTE IMS data enabled status | boolean | `true` |
| `gsm.operator.alpha` | Mobile operator name | string | `T-Mobile` |
| `gsm.operator.numeric` | Mobile country code + mobile network code | string | `310260` |
| `gsm.operator.iso-country` | ISO country code for operator | string | `us` |
| `gsm.network.type` | Current network type | string | `LTE` |
| `ril.subscription.types` | SIM subscription types | string | `NV,RUIM` |

### DNS

| Property | Description | Type | Example |
|----------|-------------|------|---------|
| `net.dns1` | Primary DNS server | string | `8.8.8.8` |
| `net.dns2` | Secondary DNS server | string | `8.8.4.4` |
| `net.dns3` | Tertiary DNS server | string | `1.1.1.1` |
| `net.dns4` | Quaternary DNS server | string | `1.0.0.1` |
| `net.rmnet0.dns1` | Primary DNS for rmnet0 interface | string | `8.8.8.8` |
| `net.rmnet0.dns2` | Secondary DNS for rmnet0 interface | string | `8.8.4.4` |
| `dhcp.wlan0.dns1` | Primary DNS from DHCP for wlan0 | string | `192.168.1.1` |
| `dhcp.wlan0.dns2` | Secondary DNS from DHCP for wlan0 | string | `192.168.1.254` |

### Network Interfaces

| Property | Description | Type | Example |
|----------|-------------|------|---------|
| `net.hostname` | Device hostname | string | `android-device` |
| `net.change` | Network change counter | integer | `1` |
| `net.tcp.buffersize.default` | Default TCP buffer sizes | string | `4096,87380,110208,4096,16384,110208` |
| `net.tcp.buffersize.wifi` | TCP buffer sizes for WiFi | string | `524288,1048576,2097152,262144,524288,1048576` |
| `net.tcp.buffersize.lte` | TCP buffer sizes for LTE | string | `524288,1048576,2097152,262144,524288,1048576` |
| `net.tcp.buffersize.umts` | TCP buffer sizes for UMTS | string | `58254,349525,1048576,58254,349525,1048576` |
| `net.tcp.buffersize.hspa` | TCP buffer sizes for HSPA | string | `40778,244668,734003,16777,100663,301990` |
| `net.tcp.buffersize.edge` | TCP buffer sizes for EDGE | string | `4093,26280,70800,4096,16384,70800` |
| `net.tcp.buffersize.gprs` | TCP buffer sizes for GPRS | string | `4092,8760,48000,4096,8760,48000` |
| `net.tcp.default_init_rwnd` | TCP default initial receive window | integer | `60` |

### Proxy

| Property | Description | Type | Example |
|----------|-------------|------|---------|
| `net.gprs.http-proxy` | HTTP proxy for GPRS | string | `proxy.example.com:8080` |
| `net.http.proxy` | Global HTTP proxy | string | `proxy.example.com:8080` |

### VPN

| Property | Description | Type | Example |
|----------|-------------|------|---------|
| `vpn.version` | VPN version | string | `1.0` |

### Tethering

| Property | Description | Type | Example |
|----------|-------------|------|---------|
| `net.tethering.noprovisioning` | Disable tethering provisioning check | boolean | `true` |
| `tether.interface` | Tethering interface name | string | `usb0` |

### IPv6

| Property | Description | Type | Example |
|----------|-------------|------|---------|
| `net.ipv6.autoconf.wlan0` | IPv6 autoconfiguration for wlan0 | boolean | `1` |
| `persist.net.doxlat` | Enable XLAT (IPv4 over IPv6) | boolean | `true` |

### DHCP

| Property | Description | Type | Example |
|----------|-------------|------|---------|
| `dhcp.wlan0.result` | DHCP result for wlan0 | string | `ok` |
| `dhcp.wlan0.ipaddress` | IP address from DHCP for wlan0 | string | `192.168.1.100` |
| `dhcp.wlan0.gateway` | Gateway from DHCP for wlan0 | string | `192.168.1.1` |
| `dhcp.wlan0.mask` | Netmask from DHCP for wlan0 | string | `255.255.255.0` |
| `dhcp.wlan0.leasetime` | DHCP lease time for wlan0 | integer | `3600` |
| `dhcp.wlan0.server` | DHCP server for wlan0 | string | `192.168.1.1` |

### Radio

| Property | Description | Type | Example |
|----------|-------------|------|---------|
| `ril.radio.state` | Radio state (on/off) | string | `on` |
| `persist.radio.apm_sim_not_pwdn` | Keep SIM powered in airplane mode | boolean | `1` |
| `persist.radio.airplane_mode_on` | Airplane mode state | boolean | `0` |

### Connectivity

| Property | Description | Type | Example |
|----------|-------------|------|---------|
| `net.qtaguid_enabled` | Enable network quota and tagging | boolean | `1` |
| `net.redirect_socket_calls.hooked` | Socket call redirection hook status | boolean | `true` |
| `persist.netd.stable_secret` | Network daemon stable secret for IPv6 | string | `fe80::1` |

### Routing

| Property | Description | Type | Example |
|----------|-------------|------|---------|
| `net.rmnet0.gw` | Gateway for rmnet0 interface | string | `10.0.0.1` |
| `net.wlan0.gw` | Gateway for wlan0 interface | string | `192.168.1.1` |

### NFC

| Property | Description | Type | Example |
|----------|-------------|------|---------|
| `net.nfc.port` | NFC communication port | integer | `6000` |

### Bluetooth

| Property | Description | Type | Example |
|----------|-------------|------|---------|
| `bluetooth.enable_timeout_ms` | Bluetooth enable timeout in milliseconds | integer | `8000` |
| `net.bt.name` | Bluetooth device name | string | `Android Device` |

## Environment Variables

Environment variables that affect network configuration:

| Variable | Description | Type | Example |
|----------|-------------|------|---------|
| `ANDROID_DNS_MODE` | DNS resolution mode (values: 'local' for device-local resolution, 'remote' for network DNS servers) | string | `local` |
| `ANDROID_SOCKET_*` | Socket file descriptor numbers for named sockets (e.g., ANDROID_SOCKET_zygote contains the FD number) | integer | `10` |
| `HOSTNAME` | Device hostname | string | `localhost` |
| `http_proxy` | HTTP proxy URL | string | `http://proxy.example.com:8080` |
| `https_proxy` | HTTPS proxy URL | string | `https://proxy.example.com:8080` |
| `ftp_proxy` | FTP proxy URL | string | `ftp://proxy.example.com:21` |
| `no_proxy` | Comma-separated list of hosts to bypass proxy | string | `localhost,127.0.0.1,.local` |
| `all_proxy` | Proxy for all protocols | string | `socks5://proxy.example.com:1080` |

## Kernel Parameters

Network-related kernel parameters accessible via `/proc/sys/net/`:

### IPv4 Settings

| Parameter | Description | Type | Example |
|----------|-------------|------|---------|
| `/proc/sys/net/ipv4/ip_forward` | Enable IPv4 forwarding | boolean | `0` |
| `/proc/sys/net/ipv4/tcp_keepalive_time` | TCP keepalive time in seconds | integer | `7200` |
| `/proc/sys/net/ipv4/tcp_keepalive_intvl` | TCP keepalive probe interval | integer | `75` |
| `/proc/sys/net/ipv4/tcp_keepalive_probes` | Number of TCP keepalive probes | integer | `9` |
| `/proc/sys/net/ipv4/tcp_fin_timeout` | TCP FIN timeout | integer | `60` |
| `/proc/sys/net/ipv4/tcp_tw_reuse` | Enable TCP TIME_WAIT socket reuse | boolean | `1` |
| `/proc/sys/net/ipv4/tcp_tw_recycle` | Enable fast TCP TIME_WAIT socket recycling (DEPRECATED: removed in Linux kernel 4.12+, unsafe with NAT) | boolean | `0` |
| `/proc/sys/net/ipv4/tcp_syncookies` | Enable TCP SYN cookies | boolean | `1` |
| `/proc/sys/net/ipv4/tcp_max_syn_backlog` | Maximum SYN backlog queue size | integer | `2048` |
| `/proc/sys/net/ipv4/tcp_rmem` | TCP read buffer sizes (min, default, max) | string | `4096 87380 6291456` |
| `/proc/sys/net/ipv4/tcp_wmem` | TCP write buffer sizes (min, default, max) | string | `4096 16384 4194304` |
| `/proc/sys/net/ipv4/ip_local_port_range` | Local port range for outgoing connections | string | `32768 60999` |
| `/proc/sys/net/ipv4/conf/all/rp_filter` | Reverse path filtering | integer | `1` |
| `/proc/sys/net/ipv4/conf/all/accept_source_route` | Accept source routed packets | boolean | `0` |
| `/proc/sys/net/ipv4/icmp_echo_ignore_all` | Ignore all ICMP echo requests | boolean | `0` |
| `/proc/sys/net/ipv4/icmp_echo_ignore_broadcasts` | Ignore broadcast ICMP echo requests | boolean | `1` |

### IPv6 Settings

| Parameter | Description | Type | Example |
|----------|-------------|------|---------|
| `/proc/sys/net/ipv6/conf/all/disable_ipv6` | Disable IPv6 on all interfaces | boolean | `0` |
| `/proc/sys/net/ipv6/conf/all/forwarding` | Enable IPv6 forwarding | boolean | `0` |
| `/proc/sys/net/ipv6/conf/all/accept_ra` | Accept router advertisements | integer | `1` |

### Core Network Settings

| Parameter | Description | Type | Example |
|----------|-------------|------|---------|
| `/proc/sys/net/core/rmem_default` | Default receive buffer size | integer | `262144` |
| `/proc/sys/net/core/rmem_max` | Maximum receive buffer size | integer | `8388608` |
| `/proc/sys/net/core/wmem_default` | Default send buffer size | integer | `262144` |
| `/proc/sys/net/core/wmem_max` | Maximum send buffer size | integer | `8388608` |
| `/proc/sys/net/core/netdev_max_backlog` | Maximum network device backlog | integer | `5000` |

## Network Interface Files

Network interface information available via `/sys/class/net/`:

| File Path | Description | Type | Example |
|----------|-------------|------|---------|
| `/sys/class/net/wlan0/address` | WiFi MAC address | string | `00:11:22:33:44:55` |
| `/sys/class/net/wlan0/operstate` | WiFi operational state | string | `up` |
| `/sys/class/net/wlan0/mtu` | WiFi MTU size | integer | `1500` |
| `/sys/class/net/rmnet0/address` | Mobile data MAC address | string | `00:00:00:00:00:00` |
| `/sys/class/net/rmnet0/operstate` | Mobile data operational state | string | `unknown` |

## Android Settings

Network-related settings accessible via Android Settings database:

| Setting | Description | Type | Example |
|----------|-------------|------|---------|
| `settings.global.airplane_mode_on` | Airplane mode setting | boolean | `0` |
| `settings.global.wifi_on` | WiFi enabled setting | boolean | `1` |
| `settings.global.mobile_data` | Mobile data enabled setting | boolean | `1` |
| `settings.global.data_roaming` | Data roaming enabled setting | boolean | `0` |
| `settings.global.wifi_sleep_policy` | WiFi sleep policy | integer | `2` |
| `settings.global.wifi_device_owner_configs_lockdown` | WiFi config lockdown by device owner | boolean | `0` |
| `settings.global.http_proxy` | Global HTTP proxy | string | `proxy.example.com:8080` |
| `settings.global.network_preference` | Preferred network type | integer | `1` |

## Usage Notes

### Property Naming Conventions

- **`persist.*`**: Properties with this prefix are persisted across reboots
- **`ro.*`**: Read-only properties set at boot time
- **`net.*`**: Network-related properties
- **`dhcp.<interface>.*`**: DHCP-related properties for specific interfaces
- **`gsm.*`**: GSM/mobile network properties
- **`ril.*`**: Radio Interface Layer properties

### Interface Naming

Interface names may vary by device and Android version:
- **WiFi**: `wlan0`, `wlan1`
- **Mobile Data**: `rmnet0`, `rmnet_data0`, `rmnet_data1`
- **Ethernet**: `eth0`, `eth1`
- **WiFi Direct**: `p2p0`
- **Bluetooth PAN**: `bt-pan`
- **USB Tethering**: `usb0`, `rndis0`

### Accessing Properties

**Command Line:**
```bash
# Get a specific property
getprop wifi.interface

# Get all properties
getprop

# Set a property (requires root)
setprop net.hostname mydevice
```

**Java/Kotlin:**
```java
// Using SystemProperties (requires system privileges)
String wifiInterface = android.os.SystemProperties.get("wifi.interface");

// Using Settings API
Settings.Global.getInt(context.getContentResolver(), Settings.Global.AIRPLANE_MODE_ON, 0);
```

### Security Considerations

- Many network properties require **system** or **root** permissions to read or modify
- Modifying certain properties may require **SELinux** policy changes
- Some properties are protected by Android's permission system
- Always validate input when modifying network configurations

### Reading Kernel Parameters

```bash
# Read a kernel parameter
cat /proc/sys/net/ipv4/ip_forward

# Write a kernel parameter (requires root)
echo 1 > /proc/sys/net/ipv4/ip_forward

# Or using sysctl
sysctl net.ipv4.ip_forward
sysctl -w net.ipv4.ip_forward=1
```

## Contributing

This is a living document. If you discover additional network-related configuration keys, please contribute by adding them to this collection.

## License

See LICENSE file for details.
