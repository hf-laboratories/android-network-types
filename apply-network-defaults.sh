#!/system/bin/sh
# ┌──────────────────┐
# │ ██ ██ ███████    │
# │ ██ ██ ██         │
# │ █████ █████      │
# │ ██ ██ ██         │
# │ ██ ██ ██         │
# │   Laboratories   │
# └──────────────────┘
#
# apply-network-defaults.sh
# 
# A script to apply best-effort default networking settings to an Android system
# based on the configuration defined in android-network-keys.json
#
# Copyright (C) 2024 HF Laboratories
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# Note: On Android devices, the shebang should be #!/system/bin/sh
# For testing on non-Android systems, use #!/bin/sh or #!/bin/bash
#
# Usage:
#   ./apply-network-defaults.sh [options]
#
# Options:
#   -f, --file <path>     Path to JSON configuration file (default: android-network-keys.json)
#   -v, --verbose         Enable verbose output
#   -d, --dry-run         Show what would be applied without making changes
#   -h, --help            Display this help message
#
# Requirements:
#   - Root/system permissions (for setprop, sysctl, settings commands)
#   - Standard POSIX tools (awk, sed, grep) - available by default on Android
#   - Android system with standard networking tools

# Default values
CONFIG_FILE="android-network-keys.json"
VERBOSE=0
DRY_RUN=0
SKIP_CONFIRMATION=0
BACKUP_DIR="./backups"
AUTO_BACKUP=1  # Enable automatic backup by default

# Note: SCRIPT_DIR is computed for potential future use (e.g., finding config files relative to script location)
# Get script directory in a portable way
if command -v readlink >/dev/null 2>&1 && readlink -f "$0" >/dev/null 2>&1; then
    # GNU readlink with -f flag
    SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
else
    # Fallback for POSIX sh (works on macOS, BSD, and other Unix systems)
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

# Source the JSON parser library
if [ -f "$SCRIPT_DIR/json-parser.sh" ]; then
    . "$SCRIPT_DIR/json-parser.sh"
elif [ -f "./json-parser.sh" ]; then
    . "./json-parser.sh"
else
    printf "\033[0;31m[ERROR]\033[0m json-parser.sh not found. Please ensure it is in the same directory as this script.\n"
    exit 1
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log levels
log_info() {
    printf "${GREEN}[INFO]${NC} %s\n" "$1"
}

log_warn() {
    printf "${YELLOW}[WARN]${NC} %s\n" "$1"
}

log_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
}

log_verbose() {
    if [ "$VERBOSE" -eq 1 ]; then
        printf "${BLUE}[VERBOSE]${NC} %s\n" "$1"
    fi
}

# Print help message
print_help() {
    cat << EOF
apply-network-defaults.sh - Apply default networking settings from JSON configuration

Usage:
  ./apply-network-defaults.sh [options]

Options:
  -f, --file <path>     Path to JSON configuration file (default: android-network-keys.json)
  -v, --verbose         Enable verbose output
  -d, --dry-run         Show what would be applied without making changes
  -y, --yes             Skip confirmation prompt and apply changes immediately
  -h, --help            Display this help message

Examples:
  # Apply defaults with verbose output
  ./apply-network-defaults.sh -v

  # Dry run to see what would be applied
  ./apply-network-defaults.sh -d

  # Use custom configuration file
  ./apply-network-defaults.sh -f /path/to/config.json

Automatic Backup:
  - On first run: Creates a "first-run" backup before applying changes
  - On subsequent runs: Creates a "pre-apply" backup before each application
  - Backups are stored in ./backups/ directory
  - Skipped in dry-run mode

Requirements:
  - Root/system permissions
  - Standard POSIX tools (awk, sed, grep) - available by default on Android
  - Android system with networking tools (setprop, sysctl, settings)

EOF
}

# Parse command line arguments
parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -f|--file)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=1
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=1
                shift
                ;;
            -y|--yes)
                SKIP_CONFIRMATION=1
                shift
                ;;
            -h|--help)
                print_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                print_help
                exit 1
                ;;
        esac
    done
}

# Check if required tools are available
check_requirements() {
    log_info "Checking requirements..."
    
    # Check for standard POSIX tools (awk, sed, grep)
    local missing_tools=""
    
    if ! command -v awk >/dev/null 2>&1; then
        missing_tools="$missing_tools awk"
    fi
    
    if ! command -v sed >/dev/null 2>&1; then
        missing_tools="$missing_tools sed"
    fi
    
    if ! command -v grep >/dev/null 2>&1; then
        missing_tools="$missing_tools grep"
    fi
    
    if [ -n "$missing_tools" ]; then
        log_error "Required tools not found: $missing_tools"
        log_error "These tools are needed for JSON parsing and should be available on Android by default."
        exit 1
    fi
    
    # Check if config file exists
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
    
    log_verbose "All requirements satisfied"
}

# Ask for user confirmation before applying changes
confirm_changes() {
    # Skip confirmation if in dry-run mode or -y flag was used
    if [ "$DRY_RUN" -eq 1 ] || [ "$SKIP_CONFIRMATION" -eq 1 ]; then
        return 0
    fi
    
    echo ""
    printf "${YELLOW}WARNING:${NC} This will apply default network settings to your system.\n"
    printf "This may change your current network configuration.\n"
    echo ""
    printf "Are you sure you want to continue? (yes/no): "
    
    read -r response
    
    case "$response" in
        [Yy]|[Yy][Ee][Ss])
            log_info "Proceeding with configuration changes..."
            return 0
            ;;
        *)
            log_info "Operation cancelled by user."
            exit 0
            ;;
    esac
}

# Create automatic backup before applying changes
create_auto_backup() {
    # Skip backup in dry-run mode
    if [ "$DRY_RUN" -eq 1 ]; then
        log_verbose "Skipping backup in dry-run mode"
        return 0
    fi
    
    # Check if backup script is available
    if [ ! -f "$SCRIPT_DIR/backup-network-settings.sh" ]; then
        log_warn "backup-network-settings.sh not found, skipping automatic backup"
        return 1
    fi
    
    log_info "Creating automatic backup before applying changes..."
    
    # Check if this is first run (no backups directory or empty)
    local backup_type=""
    local backup_desc=""
    
    # Generate timestamp for unique backup name
    local backup_timestamp="$(date '+%Y%m%d_%H%M%S')"
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        backup_type="first-run-${backup_timestamp}"
        backup_desc="Automatic backup on first run"
        log_info "First run detected - creating initial backup"
    else
        backup_type="pre-apply-${backup_timestamp}"
        backup_desc="Automatic backup before applying defaults"
        log_verbose "Creating backup before applying changes"
    fi
    
    # Create backup using backup script
    local backup_output
    if [ "$VERBOSE" -eq 1 ]; then
        backup_output=$(sh "$SCRIPT_DIR/backup-network-settings.sh" -n "$backup_type" -d "$backup_desc" -o "$BACKUP_DIR" -v 2>&1)
    else
        backup_output=$(sh "$SCRIPT_DIR/backup-network-settings.sh" -n "$backup_type" -d "$backup_desc" -o "$BACKUP_DIR" 2>&1)
    fi
    
    local backup_status=$?
    
    if [ $backup_status -eq 0 ]; then
        log_info "Backup created successfully"
        if [ "$VERBOSE" -eq 1 ]; then
            echo "$backup_output" | grep "Backup saved to:" || true
        fi
    else
        log_warn "Backup failed, but continuing with apply operation"
        if [ "$VERBOSE" -eq 1 ]; then
            echo "$backup_output"
        fi
    fi
    
    echo ""
}

# Apply system property using setprop
apply_system_property() {
    local key="$1"
    local value="$2"
    local description="$3"
    
    log_verbose "Applying system property: $key = $value ($description)"
    
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "[DRY-RUN] Would set property: $key = $value"
        return 0
    fi
    
    if command -v setprop >/dev/null 2>&1; then
        if setprop "$key" "$value" 2>/dev/null; then
            log_verbose "Successfully set property: $key"
            return 0
        else
            log_warn "Failed to set property: $key (may require root or be read-only)"
            return 1
        fi
    else
        log_warn "setprop command not available, skipping property: $key"
        return 1
    fi
}

# Apply kernel parameter using sysctl or direct write
apply_kernel_parameter() {
    local path="$1"
    local value="$2"
    local description="$3"
    
    log_verbose "Applying kernel parameter: $path = $value ($description)"
    
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "[DRY-RUN] Would set kernel parameter: $path = $value"
        return 0
    fi
    
    # Check if file exists and is writable
    if [ ! -f "$path" ]; then
        log_warn "Kernel parameter path not found: $path"
        return 1
    fi
    
    # Try using sysctl first (more portable) - only for /proc/sys paths
    case "$path" in
        /proc/sys/*)
            local sysctl_key=$(echo "$path" | sed 's|^/proc/sys/||' | tr '/' '.')
            if command -v sysctl >/dev/null 2>&1; then
                local sysctl_error=$(sysctl -w "${sysctl_key}=${value}" 2>&1)
                if [ $? -eq 0 ]; then
                    log_verbose "Successfully set kernel parameter via sysctl: $path"
                    return 0
                else
                    log_verbose "sysctl failed for $path: $sysctl_error"
                fi
            fi
            ;;
    esac
    
    # Fall back to direct write
    if echo "$value" > "$path" 2>/dev/null; then
        log_verbose "Successfully set kernel parameter via direct write: $path"
        return 0
    else
        log_warn "Failed to set kernel parameter: $path (may require root)"
        return 1
    fi
}

# Apply environment variable
apply_environment_variable() {
    local key="$1"
    local value="$2"
    local description="$3"
    
    log_verbose "Setting environment variable: $key = $value ($description)"
    
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "[DRY-RUN] Would set environment variable: $key = $value"
        return 0
    fi
    
    export "$key=$value"
    log_verbose "Successfully set environment variable: $key"
    return 0
}

# Apply Android settings using settings command
apply_android_setting() {
    local namespace="$1"  # global, system, or secure
    local key="$2"
    local value="$3"
    local description="$4"
    
    log_verbose "Applying Android setting: $namespace/$key = $value ($description)"
    
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "[DRY-RUN] Would set Android setting: settings put $namespace $key $value"
        return 0
    fi
    
    if command -v settings >/dev/null 2>&1; then
        if settings put "$namespace" "$key" "$value" 2>/dev/null; then
            log_verbose "Successfully set Android setting: $namespace/$key"
            return 0
        else
            log_warn "Failed to set Android setting: $namespace/$key (may require permissions)"
            return 1
        fi
    else
        log_warn "settings command not available, skipping: $namespace/$key"
        return 1
    fi
}

# Process system properties from JSON
process_system_properties() {
    log_info "Processing system properties..."
    
    local categories=$(json_get_categories "$CONFIG_FILE" "system_properties")
    
    if [ -z "$categories" ]; then
        log_warn "No system properties found in configuration"
        return
    fi
    
    for category in $categories; do
        log_verbose "Processing category: $category"
        
        # Get all properties in this category
        local properties=$(json_get_category_keys "$CONFIG_FILE" "system_properties" "$category")
        
        for prop in $properties; do
            # Check if property has a default value
            local default_value=$(json_get_field_value "$CONFIG_FILE" "system_properties" "$category" "$prop" "default")
            
            if [ -n "$default_value" ] && [ "$default_value" != "null" ]; then
                local description=$(json_get_field_value "$CONFIG_FILE" "system_properties" "$category" "$prop" "description")
                # Use default description if empty
                if [ -z "$description" ]; then
                    description="No description"
                fi
                apply_system_property "$prop" "$default_value" "$description"
            else
                log_verbose "Skipping property without default value: $prop"
            fi
        done
    done
}

# Process kernel parameters from JSON
process_kernel_parameters() {
    log_info "Processing kernel parameters..."
    
    local categories=$(json_get_categories "$CONFIG_FILE" "kernel_parameters")
    
    if [ -z "$categories" ]; then
        log_warn "No kernel parameters found in configuration"
        return
    fi
    
    for category in $categories; do
        log_verbose "Processing kernel category: $category"
        
        # Get all parameters in this category
        local params=$(json_get_category_keys "$CONFIG_FILE" "kernel_parameters" "$category")
        
        for param in $params; do
            # Check if parameter has a default value
            local default_value=$(json_get_field_value "$CONFIG_FILE" "kernel_parameters" "$category" "$param" "default")
            
            if [ -n "$default_value" ] && [ "$default_value" != "null" ]; then
                local description=$(json_get_field_value "$CONFIG_FILE" "kernel_parameters" "$category" "$param" "description")
                # Use default description if empty
                if [ -z "$description" ]; then
                    description="No description"
                fi
                apply_kernel_parameter "$param" "$default_value" "$description"
            else
                log_verbose "Skipping kernel parameter without default value: $param"
            fi
        done
    done
}

# Process environment variables from JSON
process_environment_variables() {
    log_info "Processing environment variables..."
    
    local categories=$(json_get_categories "$CONFIG_FILE" "environment_variables")
    
    if [ -z "$categories" ]; then
        log_warn "No environment variables found in configuration"
        return
    fi
    
    for category in $categories; do
        log_verbose "Processing environment category: $category"
        
        # Get all variables in this category
        local vars=$(json_get_category_keys "$CONFIG_FILE" "environment_variables" "$category")
        
        for var in $vars; do
            # Check if variable has a default value
            local default_value=$(json_get_field_value "$CONFIG_FILE" "environment_variables" "$category" "$var" "default")
            
            if [ -n "$default_value" ] && [ "$default_value" != "null" ]; then
                local description=$(json_get_field_value "$CONFIG_FILE" "environment_variables" "$category" "$var" "description")
                # Use default description if empty
                if [ -z "$description" ]; then
                    description="No description"
                fi
                apply_environment_variable "$var" "$default_value" "$description"
            else
                log_verbose "Skipping environment variable without default value: $var"
            fi
        done
    done
}

# Process Android settings from JSON
process_android_settings() {
    log_info "Processing Android settings..."
    
    local categories=$(json_get_categories "$CONFIG_FILE" "android_specific")
    
    if [ -z "$categories" ]; then
        log_warn "No Android settings found in configuration"
        return
    fi
    
    for category in $categories; do
        log_verbose "Processing Android settings category: $category"
        
        # Get all settings in this category
        local settings_keys=$(json_get_category_keys "$CONFIG_FILE" "android_specific" "$category")
        
        for setting_key in $settings_keys; do
            # Check if setting has a default value
            local default_value=$(json_get_field_value "$CONFIG_FILE" "android_specific" "$category" "$setting_key" "default")
            
            if [ -n "$default_value" ] && [ "$default_value" != "null" ]; then
                local description=$(json_get_field_value "$CONFIG_FILE" "android_specific" "$category" "$setting_key" "description")
                # Use default description if empty
                if [ -z "$description" ]; then
                    description="No description"
                fi
                
                # Validate and extract namespace and key from setting_key (format: settings.namespace.key)
                case "$setting_key" in
                    settings.*.*)
                        # Valid format: settings.namespace.key
                        # Note: The key part (f3-) may contain underscores or additional characters
                        # but should not contain dots (Android settings keys use underscores)
                        local namespace=$(echo "$setting_key" | cut -d'.' -f2)
                        local key=$(echo "$setting_key" | cut -d'.' -f3-)
                        
                        # Additional validation: ensure namespace and key are meaningful (not empty after parsing)
                        if [ -n "$namespace" ] && [ -n "$key" ] && [ "$namespace" != "$key" ]; then
                            apply_android_setting "$namespace" "$key" "$default_value" "$description"
                        else
                            log_warn "Invalid Android setting format: $setting_key (expected: settings.namespace.key with all parts present)"
                        fi
                        ;;
                    *)
                        log_warn "Skipping non-settings key or invalid format: $setting_key (expected: settings.namespace.key)"
                        ;;
                esac
            else
                log_verbose "Skipping Android setting without default value: $setting_key"
            fi
        done
    done
}

# Main function
main() {
    parse_args "$@"
    
    log_info "=========================================="
    log_info "Android Network Defaults Configuration"
    log_info "=========================================="
    log_info "Configuration file: $CONFIG_FILE"
    
    if [ "$DRY_RUN" -eq 1 ]; then
        log_warn "Running in DRY-RUN mode - no changes will be made"
    fi
    
    if [ "$VERBOSE" -eq 1 ]; then
        log_info "Verbose mode enabled"
    fi
    
    echo ""
    
    # Check requirements
    check_requirements
    
    echo ""
    
    # Ask for confirmation before applying changes
    confirm_changes
    
    # Create automatic backup before applying changes
    create_auto_backup
    
    echo ""
    
    # Process all configuration categories
    process_system_properties
    echo ""
    
    process_kernel_parameters
    echo ""
    
    process_environment_variables
    echo ""
    
    process_android_settings
    echo ""
    
    log_info "=========================================="
    log_info "Configuration application complete"
    log_info "=========================================="
    
    if [ "$DRY_RUN" -eq 1 ]; then
        log_info "This was a dry run. Re-run without -d to apply changes."
    fi
}

# Run main function with all arguments
main "$@"
