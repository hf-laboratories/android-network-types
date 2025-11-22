#!/bin/sh
# apply-network-defaults.sh
# 
# A script to apply best-effort default networking settings to an Android system
# based on the configuration defined in android-network-keys.json
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
#   - jq or compatible JSON parser
#   - Android system with standard networking tools

# Default values
CONFIG_FILE="android-network-keys.json"
VERBOSE=0
DRY_RUN=0

# Get script directory in a portable way
if command -v readlink >/dev/null 2>&1 && readlink -f "$0" >/dev/null 2>&1; then
    # GNU readlink with -f flag
    SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
else
    # Fallback for POSIX sh (works on macOS, BSD, and other Unix systems)
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
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
  -h, --help            Display this help message

Examples:
  # Apply defaults with verbose output
  ./apply-network-defaults.sh -v

  # Dry run to see what would be applied
  ./apply-network-defaults.sh -d

  # Use custom configuration file
  ./apply-network-defaults.sh -f /path/to/config.json

Requirements:
  - Root/system permissions
  - jq for JSON parsing
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
    
    # Check for jq (JSON parser)
    if ! command -v jq >/dev/null 2>&1; then
        log_error "jq is not installed. Please install jq to parse JSON configuration."
        exit 1
    fi
    
    # Check if config file exists
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
    
    log_verbose "All requirements satisfied"
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
                if sysctl -w "${sysctl_key}=${value}" >/dev/null 2>&1; then
                    log_verbose "Successfully set kernel parameter via sysctl: $path"
                    return 0
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
    
    local categories=$(jq -r '.categories.system_properties | keys[]' "$CONFIG_FILE" 2>/dev/null || echo "")
    
    if [ -z "$categories" ]; then
        log_warn "No system properties found in configuration"
        return
    fi
    
    for category in $categories; do
        log_verbose "Processing category: $category"
        
        # Get all properties in this category
        local properties=$(jq -r ".categories.system_properties.$category | keys[]" "$CONFIG_FILE" 2>/dev/null || echo "")
        
        for prop in $properties; do
            # Check if property has a default value
            local default_value=$(jq -r ".categories.system_properties.$category.\"$prop\".default // empty" "$CONFIG_FILE" 2>/dev/null)
            
            if [ -n "$default_value" ] && [ "$default_value" != "null" ]; then
                local description=$(jq -r ".categories.system_properties.$category.\"$prop\".description // \"No description\"" "$CONFIG_FILE" 2>/dev/null)
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
    
    local categories=$(jq -r '.categories.kernel_parameters | keys[]' "$CONFIG_FILE" 2>/dev/null || echo "")
    
    if [ -z "$categories" ]; then
        log_warn "No kernel parameters found in configuration"
        return
    fi
    
    for category in $categories; do
        log_verbose "Processing kernel category: $category"
        
        # Get all parameters in this category
        local params=$(jq -r ".categories.kernel_parameters.$category | keys[]" "$CONFIG_FILE" 2>/dev/null || echo "")
        
        for param in $params; do
            # Check if parameter has a default value
            local default_value=$(jq -r ".categories.kernel_parameters.$category.\"$param\".default // empty" "$CONFIG_FILE" 2>/dev/null)
            
            if [ -n "$default_value" ] && [ "$default_value" != "null" ]; then
                local description=$(jq -r ".categories.kernel_parameters.$category.\"$param\".description // \"No description\"" "$CONFIG_FILE" 2>/dev/null)
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
    
    local categories=$(jq -r '.categories.environment_variables | keys[]' "$CONFIG_FILE" 2>/dev/null || echo "")
    
    if [ -z "$categories" ]; then
        log_warn "No environment variables found in configuration"
        return
    fi
    
    for category in $categories; do
        log_verbose "Processing environment category: $category"
        
        # Get all variables in this category
        local vars=$(jq -r ".categories.environment_variables.$category | keys[]" "$CONFIG_FILE" 2>/dev/null || echo "")
        
        for var in $vars; do
            # Check if variable has a default value
            local default_value=$(jq -r ".categories.environment_variables.$category.\"$var\".default // empty" "$CONFIG_FILE" 2>/dev/null)
            
            if [ -n "$default_value" ] && [ "$default_value" != "null" ]; then
                local description=$(jq -r ".categories.environment_variables.$category.\"$var\".description // \"No description\"" "$CONFIG_FILE" 2>/dev/null)
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
    
    local categories=$(jq -r '.categories.android_specific | keys[]' "$CONFIG_FILE" 2>/dev/null || echo "")
    
    if [ -z "$categories" ]; then
        log_warn "No Android settings found in configuration"
        return
    fi
    
    for category in $categories; do
        log_verbose "Processing Android settings category: $category"
        
        # Get all settings in this category
        local settings_keys=$(jq -r ".categories.android_specific.$category | keys[]" "$CONFIG_FILE" 2>/dev/null || echo "")
        
        for setting_key in $settings_keys; do
            # Check if setting has a default value
            local default_value=$(jq -r ".categories.android_specific.$category.\"$setting_key\".default // empty" "$CONFIG_FILE" 2>/dev/null)
            
            if [ -n "$default_value" ] && [ "$default_value" != "null" ]; then
                local description=$(jq -r ".categories.android_specific.$category.\"$setting_key\".description // \"No description\"" "$CONFIG_FILE" 2>/dev/null)
                
                # Validate and extract namespace and key from setting_key (format: settings.namespace.key)
                case "$setting_key" in
                    settings.*.*)
                        # Valid format: settings.namespace.key
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
