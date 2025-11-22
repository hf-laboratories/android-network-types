# Generic Settings Application Utility

## Overview

The `/alt` directory contains a generic, open-ended configuration utility that can apply any type of system settings from a JSON configuration file. Unlike the main network-specific scripts, this utility works with arbitrary categories and key-value pairs, making it suitable for any system configuration needs.

## Features

- **Open-ended categories**: Define any category name for organizing settings
- **Generic key-value pairs**: Apply any setting without predefined structure
- **Multiple setting types**: Supports system properties, kernel parameters, environment variables, Android settings, and custom commands
- **Flexible configuration**: JSON-based configuration with descriptive metadata
- **Dry-run mode**: Preview changes before applying
- **Category filtering**: Apply only specific categories
- **Verbose logging**: Detailed output of operations

## Files

### generic-apply-settings.sh

Main script that applies settings from a JSON configuration file.

**Usage:**
```bash
./generic-apply-settings.sh [options]
```

**Options:**
- `-f, --file <path>` - Path to JSON configuration file (default: config.json)
- `-c, --category <name>` - Apply only specific category
- `-v, --verbose` - Enable verbose output
- `-d, --dry-run` - Show what would be applied without making changes
- `-y, --yes` - Skip confirmation prompt
- `-h, --help` - Display help message

### template-config.json

Template showing the expected JSON configuration format with examples for all supported setting types.

## Configuration Format

The configuration file follows this structure:

```json
{
  "version": "1.0",
  "description": "Description of this configuration",
  "categories": {
    "category_name": {
      "description": "Category description",
      "settings": {
        "key_name": {
          "value": "value_to_set",
          "description": "What this setting does"
        }
      }
    }
  }
}
```

### Supported Category Types

The utility recognizes these special category types and handles them appropriately:

#### 1. system_properties
Android system properties set via `setprop` command.

```json
"system_properties": {
  "settings": {
    "persist.example.setting": {
      "value": "1",
      "description": "Example system property"
    }
  }
}
```

#### 2. kernel_parameters
Linux kernel parameters set via `sysctl` or direct writes to `/proc/sys/`.

```json
"kernel_parameters": {
  "settings": {
    "/proc/sys/net/ipv4/ip_forward": {
      "value": "1",
      "description": "Enable IP forwarding"
    }
  }
}
```

#### 3. environment_variables
Environment variables exported to the shell session.

```json
"environment_variables": {
  "settings": {
    "MY_VAR": {
      "value": "my_value",
      "description": "Custom environment variable"
    }
  }
}
```

#### 4. android_settings
Android Settings database entries set via `settings` command.
Keys must follow format: `settings.namespace.key`

```json
"android_settings": {
  "settings": {
    "settings.global.airplane_mode_on": {
      "value": "0",
      "description": "Airplane mode setting"
    }
  }
}
```

#### 5. custom_commands
Custom shell commands to execute.

```json
"custom_commands": {
  "settings": {
    "setup_network": {
      "value": "ip link set eth0 up",
      "description": "Bring up eth0 interface"
    }
  }
}
```

#### 6. Custom Categories
Any other category name you define will be treated as generic key-value pairs and logged. You can extend the script to handle custom categories as needed.

```json
"my_custom_category": {
  "settings": {
    "custom_key": {
      "value": "custom_value",
      "description": "Custom setting"
    }
  }
}
```

## Examples

### Example 1: Apply All Settings

```bash
# Apply all settings from config
./generic-apply-settings.sh -f myconfig.json -y
```

### Example 2: Preview Changes

```bash
# Dry-run to see what would be applied
./generic-apply-settings.sh -f myconfig.json -d -v
```

### Example 3: Apply Specific Category

```bash
# Apply only system properties
./generic-apply-settings.sh -f myconfig.json -c system_properties
```

### Example 4: Custom Configuration

Create a custom configuration file:

```json
{
  "version": "1.0",
  "description": "My custom system configuration",
  "categories": {
    "system_properties": {
      "settings": {
        "debug.my_app.enabled": {
          "value": "1",
          "description": "Enable my app debugging"
        }
      }
    },
    "kernel_parameters": {
      "settings": {
        "/proc/sys/vm/swappiness": {
          "value": "10",
          "description": "Set swappiness to 10"
        }
      }
    }
  }
}
```

Apply it:
```bash
./generic-apply-settings.sh -f mycustom.json -v
```

## Use Cases

### System Optimization

Create configurations for different performance profiles:

```bash
# gaming-profile.json
{
  "categories": {
    "system_properties": {
      "settings": {
        "persist.sys.performance_mode": {"value": "high", "description": "High performance mode"}
      }
    },
    "kernel_parameters": {
      "settings": {
        "/proc/sys/vm/swappiness": {"value": "10", "description": "Reduce swap"}
      }
    }
  }
}
```

### Development Environment

Configure development settings:

```bash
# dev-config.json
{
  "categories": {
    "android_settings": {
      "settings": {
        "settings.global.adb_enabled": {"value": "1", "description": "Enable ADB"}
      }
    },
    "environment_variables": {
      "settings": {
        "ANDROID_HOME": {"value": "/opt/android-sdk", "description": "Android SDK path"}
      }
    }
  }
}
```

### Application-Specific Settings

Configure settings for specific applications:

```bash
# app-config.json
{
  "categories": {
    "app_settings": {
      "description": "Application-specific settings",
      "settings": {
        "app.example.timeout": {"value": "30", "description": "App timeout in seconds"},
        "app.example.debug": {"value": "true", "description": "Enable debug mode"}
      }
    }
  }
}
```

## Integration with Backup/Restore

The generic utility can work alongside the backup/restore scripts:

```bash
# Backup current state before applying
cd ..
./backup-network-settings.sh -n "pre-custom-config"

# Apply custom configuration
cd alt
./generic-apply-settings.sh -f myconfig.json -y

# If something goes wrong, restore
cd ..
./restore-network-settings.sh -n "pre-custom-config" -y
```

## Requirements

- Standard POSIX tools (awk, sed, grep) - available by default on Android
- `json-parser.sh` from parent directory
- Root/system permissions (for most operations)
- Android system tools (setprop, settings, sysctl) depending on what you're configuring

## Permissions

Different setting types require different permissions:

| Setting Type | Required Permission |
|--------------|-------------------|
| System Properties | User or root (some require root) |
| Kernel Parameters | Root |
| Environment Variables | User |
| Android Settings | User or root (depends on namespace) |
| Custom Commands | Depends on command |

## Extending the Utility

### Adding Custom Category Handlers

To add support for new category types, modify the `process_category()` function:

```bash
case "$category" in
    system_properties)
        apply_system_property "$current_key" "$current_value" "$current_desc"
        ;;
    my_custom_category)
        # Add your custom handler here
        handle_my_custom_setting "$current_key" "$current_value" "$current_desc"
        ;;
    *)
        # Generic handler
        log_info "Generic setting: $current_key = $current_value"
        ;;
esac
```

### Creating Configuration Templates

You can create multiple template files for different purposes:

- `template-config.json` - General template with all examples
- `network-template.json` - Network-specific settings
- `performance-template.json` - Performance optimization settings
- `security-template.json` - Security hardening settings

## Troubleshooting

### "json-parser.sh not found"

Ensure the parent directory contains `json-parser.sh`:
```bash
ls ../json-parser.sh
```

### "Configuration file not found"

Specify the full path to your config file:
```bash
./generic-apply-settings.sh -f /path/to/config.json
```

### Settings not applying

- Verify you have appropriate permissions (root for most operations)
- Use verbose mode to see detailed errors: `-v`
- Try dry-run mode first to preview: `-d -v`

### Custom category not working

Custom categories are logged but not automatically applied. Extend the script to add custom handlers for your specific needs.

## Comparison with Main Utility

| Feature | Main Utility | Alt/Generic Utility |
|---------|-------------|-------------------|
| Purpose | Network settings only | Any system settings |
| Structure | Fixed categories | Open-ended categories |
| Keys | Predefined network keys | Any key-value pairs |
| Defaults | Has default values | User-defined only |
| Comparison | Can compare to defaults | No comparison |
| Complexity | More features | Simpler, more flexible |

## License

GNU General Public License v3.0 (GPLv3) - See LICENSE file for details.

## Related Files

- `../json-parser.sh` - JSON parsing library
- `template-config.json` - Configuration template
- `../backup-network-settings.sh` - Backup utility
- `../restore-network-settings.sh` - Restore utility
