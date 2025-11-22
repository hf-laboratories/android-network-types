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
# read-network-settings.sh
# 
# A script to read and display current network settings from an Android system
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
#   ./read-network-settings.sh [options]
#
# Options:
#   -f, --file <path>          Path to JSON configuration file (default: android-network-keys.json)
#   -o, --output <format>      Output format: json, table, or compact (default: table)
#   -c, --category <category>  Filter by specific category (e.g., wifi, dns, proxy)
#   -s, --compare-defaults     Compare current values against defaults
#   -v, --verbose              Enable verbose output
#   -h, --help                 Display this help message
#
# Requirements:
#   - Standard POSIX tools (awk, sed, grep) - available by default on Android
#   - Android system with standard networking tools (optional: getprop, settings)

# Default values
CONFIG_FILE="android-network-keys.json"
OUTPUT_FORMAT="table"
CATEGORY_FILTER=""
COMPARE_DEFAULTS=0
VERBOSE=0

# Note: SCRIPT_DIR is computed for potential future use
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
    log_error "json-parser.sh not found. Please ensure it is in the same directory as this script."
    exit 1
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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
read-network-settings.sh - Read and display current network settings from Android system

Usage:
  ./read-network-settings.sh [options]

Options:
  -f, --file <path>          Path to JSON configuration file (default: android-network-keys.json)
  -o, --output <format>      Output format: json, table, or compact (default: table)
  -c, --category <category>  Filter by specific category (e.g., wifi, dns, proxy)
  -s, --compare-defaults     Compare current values against defaults
  -v, --verbose              Enable verbose output
  -h, --help                 Display this help message

Examples:
  # Read all network settings in table format
  ./read-network-settings.sh

  # Read settings in JSON format
  ./read-network-settings.sh -o json

  # Read only WiFi-related settings
  ./read-network-settings.sh -c wifi

  # Compare current values with defaults
  ./read-network-settings.sh -s

  # Compact output for quick overview
  ./read-network-settings.sh -o compact

Requirements:
  - Standard POSIX tools (awk, sed, grep) - available by default on Android
  - Android system with networking tools (getprop, settings, etc.)

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
            -o|--output)
                OUTPUT_FORMAT="$2"
                if [ "$OUTPUT_FORMAT" != "json" ] && [ "$OUTPUT_FORMAT" != "table" ] && [ "$OUTPUT_FORMAT" != "compact" ]; then
                    log_error "Invalid output format: $OUTPUT_FORMAT (must be json, table, or compact)"
                    exit 1
                fi
                shift 2
                ;;
            -c|--category)
                CATEGORY_FILTER="$2"
                shift 2
                ;;
            -s|--compare-defaults)
                COMPARE_DEFAULTS=1
                shift
                ;;
            -v|--verbose)
                VERBOSE=1
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
    log_verbose "Checking requirements..."
    
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

# Read system property using getprop
read_system_property() {
    local key="$1"
    
    if command -v getprop >/dev/null 2>&1; then
        local value=$(getprop "$key" 2>/dev/null)
        echo "$value"
    else
        echo ""
    fi
}

# Read kernel parameter from /proc/sys/net/
read_kernel_parameter() {
    local path="$1"
    
    if [ -f "$path" ] && [ -r "$path" ]; then
        local value=$(cat "$path" 2>/dev/null)
        echo "$value"
    else
        echo ""
    fi
}

# Read environment variable
read_environment_variable() {
    local key="$1"
    
    printenv "$key" 2>/dev/null || echo ""
}

# Read Android settings using settings command
read_android_setting() {
    local namespace="$1"
    local key="$2"
    
    if command -v settings >/dev/null 2>&1; then
        local value=$(settings get "$namespace" "$key" 2>/dev/null)
        if [ "$value" = "null" ]; then
            echo ""
        else
            echo "$value"
        fi
    else
        echo ""
    fi
}

# JSON output globals
JSON_FIRST_ITEM=1

# Escape special characters for JSON strings
escape_json_string() {
    local str="$1"
    # Read entire input into pattern space, then escape special characters
    # Escape backslashes first, then quotes, forward slashes, and control characters
    # Pattern breakdown:
    #   :a;N;$!ba - Read entire input into pattern space (handles multiline strings)
    #   s/\\/\\\\/g - Escape backslashes (\\ -> \\\\)
    #   s/"/\\"/g - Escape double quotes (\" -> \\\")
    #   s/\//\\\//g - Escape forward slashes (/ -> \\/)
    #   s/\t/\\t/g - Escape tabs
    #   s/\r/\\r/g - Escape carriage returns
    #   s/\n/\\n/g - Escape newlines
    echo "$str" | sed ':a;N;$!ba;s/\\/\\\\/g; s/"/\\"/g; s/\//\\\//g; s/\t/\\t/g; s/\r/\\r/g; s/\n/\\n/g'
}

# Initialize JSON output
init_json_output() {
    echo "{"
    echo "  \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
    echo "  \"network_settings\": {"
}

# Finalize JSON output
finalize_json_output() {
    echo ""
    echo "  }"
    echo "}"
}

# Add JSON category
add_json_category() {
    local category="$1"
    local type="$2"
    
    if [ "$JSON_FIRST_ITEM" -eq 0 ]; then
        echo ","
    fi
    JSON_FIRST_ITEM=0
    
    printf "    \"%s_%s\": {" "$type" "$category"
}

# Close JSON category
close_json_category() {
    echo ""
    printf "    }"
}

# Add JSON property
add_json_property() {
    local key="$1"
    local value="$2"
    local default="$3"
    local description="$4"
    local first_in_category="$5"
    
    if [ "$first_in_category" -eq 0 ]; then
        echo ","
    fi
    
    # Escape special characters in JSON strings using helper function
    value=$(escape_json_string "$value")
    default=$(escape_json_string "$default")
    description=$(escape_json_string "$description")
    
    printf "      \"%s\": {" "$key"
    printf " \"current\": \"%s\", \"default\": \"%s\", \"description\": \"%s\"" "$value" "$default" "$description"
    if [ "$COMPARE_DEFAULTS" -eq 1 ]; then
        if [ "$value" = "$default" ]; then
            printf ", \"matches_default\": true"
        else
            printf ", \"matches_default\": false"
        fi
    fi
    printf " }"
}

# Print table header
print_table_header() {
    local category="$1"
    local type="$2"
    
    echo ""
    printf "${CYAN}========================================${NC}\n"
    printf "${CYAN}%s - %s${NC}\n" "$type" "$category"
    printf "${CYAN}========================================${NC}\n"
    
    if [ "$COMPARE_DEFAULTS" -eq 1 ]; then
        printf "%-50s | %-30s | %-30s | %s\n" "Key" "Current Value" "Default Value" "Match"
        printf "%.50s-+-%.30s-+-%.30s-+-%.5s\n" "--------------------------------------------------" "------------------------------" "------------------------------" "-----"
    else
        printf "%-50s | %-50s\n" "Key" "Current Value"
        printf "%.50s-+-%.50s\n" "--------------------------------------------------" "--------------------------------------------------"
    fi
}

# Print table row
print_table_row() {
    local key="$1"
    local value="$2"
    local default="$3"
    
    # Truncate long values for display using POSIX-compliant method
    local display_value="$value"
    local display_default="$default"
    
    # Use cut to truncate if longer than 50 characters
    if [ ${#display_value} -gt 50 ]; then
        display_value="$(echo "$value" | cut -c1-47)..."
    fi
    
    # Use cut to truncate if longer than 30 characters
    if [ ${#display_default} -gt 30 ]; then
        display_default="$(echo "$default" | cut -c1-27)..."
    fi
    
    if [ "$COMPARE_DEFAULTS" -eq 1 ]; then
        if [ "$value" = "$default" ]; then
            printf "%-50s | %-30s | %-30s | ${GREEN}✓${NC}\n" "$key" "$display_value" "$display_default"
        else
            printf "%-50s | %-30s | %-30s | ${RED}✗${NC}\n" "$key" "$display_value" "$display_default"
        fi
    else
        printf "%-50s | %-50s\n" "$key" "$display_value"
    fi
}

# Print compact format
print_compact() {
    local key="$1"
    local value="$2"
    local default="$3"
    
    if [ "$COMPARE_DEFAULTS" -eq 1 ]; then
        if [ "$value" = "$default" ]; then
            printf "${GREEN}✓${NC} %s=%s\n" "$key" "$value"
        else
            printf "${RED}✗${NC} %s=%s (default: %s)\n" "$key" "$value" "$default"
        fi
    else
        printf "%s=%s\n" "$key" "$value"
    fi
}

# Process system properties from JSON
process_system_properties() {
    log_verbose "Reading system properties..."
    
    local categories=$(json_get_categories "$CONFIG_FILE" "system_properties")
    
    if [ -z "$categories" ]; then
        log_warn "No system properties found in configuration"
        return
    fi
    
    local category_started=0
    local first_in_category=1
    
    for category in $categories; do
        # Apply category filter if specified
        if [ -n "$CATEGORY_FILTER" ] && [ "$category" != "$CATEGORY_FILTER" ]; then
            continue
        fi
        
        log_verbose "Processing category: $category"
        
        # Get all properties in this category
        local properties=$(json_get_category_keys "$CONFIG_FILE" "system_properties" "$category")
        
        local has_properties=0
        for prop in $properties; do
            has_properties=1
            break
        done
        
        if [ "$has_properties" -eq 0 ]; then
            continue
        fi
        
        # Start category output based on format
        if [ "$OUTPUT_FORMAT" = "json" ]; then
            add_json_category "$category" "system_property"
            first_in_category=1
        elif [ "$OUTPUT_FORMAT" = "table" ]; then
            print_table_header "$category" "System Properties"
        fi
        
        for prop in $properties; do
            local current_value=$(read_system_property "$prop")
            local default_value=$(json_get_field_value "$CONFIG_FILE" "system_properties" "$category" "$prop" "default")
            local description=$(json_get_field_value "$CONFIG_FILE" "system_properties" "$category" "$prop" "description")
            
            # Use default description if empty
            if [ -z "$description" ]; then
                description="No description"
            fi
            
            if [ "$OUTPUT_FORMAT" = "json" ]; then
                add_json_property "$prop" "$current_value" "$default_value" "$description" "$first_in_category"
                first_in_category=0
            elif [ "$OUTPUT_FORMAT" = "table" ]; then
                print_table_row "$prop" "$current_value" "$default_value"
            elif [ "$OUTPUT_FORMAT" = "compact" ]; then
                print_compact "$prop" "$current_value" "$default_value"
            fi
        done
        
        if [ "$OUTPUT_FORMAT" = "json" ]; then
            close_json_category
        fi
    done
}

# Process kernel parameters from JSON
process_kernel_parameters() {
    log_verbose "Reading kernel parameters..."
    
    local categories=$(json_get_categories "$CONFIG_FILE" "kernel_parameters")
    
    if [ -z "$categories" ]; then
        log_warn "No kernel parameters found in configuration"
        return
    fi
    
    local first_in_category=1
    
    for category in $categories; do
        # Apply category filter if specified
        if [ -n "$CATEGORY_FILTER" ] && [ "$category" != "$CATEGORY_FILTER" ]; then
            continue
        fi
        
        log_verbose "Processing kernel category: $category"
        
        # Get all parameters in this category
        local params=$(json_get_category_keys "$CONFIG_FILE" "kernel_parameters" "$category")
        
        local has_params=0
        for param in $params; do
            has_params=1
            break
        done
        
        if [ "$has_params" -eq 0 ]; then
            continue
        fi
        
        # Start category output based on format
        if [ "$OUTPUT_FORMAT" = "json" ]; then
            add_json_category "$category" "kernel_parameter"
            first_in_category=1
        elif [ "$OUTPUT_FORMAT" = "table" ]; then
            print_table_header "$category" "Kernel Parameters"
        fi
        
        for param in $params; do
            local current_value=$(read_kernel_parameter "$param")
            local default_value=$(json_get_field_value "$CONFIG_FILE" "kernel_parameters" "$category" "$param" "default")
            local description=$(json_get_field_value "$CONFIG_FILE" "kernel_parameters" "$category" "$param" "description")
            
            # Use default description if empty
            if [ -z "$description" ]; then
                description="No description"
            fi
            
            if [ "$OUTPUT_FORMAT" = "json" ]; then
                add_json_property "$param" "$current_value" "$default_value" "$description" "$first_in_category"
                first_in_category=0
            elif [ "$OUTPUT_FORMAT" = "table" ]; then
                print_table_row "$param" "$current_value" "$default_value"
            elif [ "$OUTPUT_FORMAT" = "compact" ]; then
                print_compact "$param" "$current_value" "$default_value"
            fi
        done
        
        if [ "$OUTPUT_FORMAT" = "json" ]; then
            close_json_category
        fi
    done
}

# Process environment variables from JSON
process_environment_variables() {
    log_verbose "Reading environment variables..."
    
    local categories=$(json_get_categories "$CONFIG_FILE" "environment_variables")
    
    if [ -z "$categories" ]; then
        log_warn "No environment variables found in configuration"
        return
    fi
    
    local first_in_category=1
    
    for category in $categories; do
        # Apply category filter if specified
        if [ -n "$CATEGORY_FILTER" ] && [ "$category" != "$CATEGORY_FILTER" ]; then
            continue
        fi
        
        log_verbose "Processing environment category: $category"
        
        # Get all variables in this category
        local vars=$(json_get_category_keys "$CONFIG_FILE" "environment_variables" "$category")
        
        local has_vars=0
        for var in $vars; do
            has_vars=1
            break
        done
        
        if [ "$has_vars" -eq 0 ]; then
            continue
        fi
        
        # Start category output based on format
        if [ "$OUTPUT_FORMAT" = "json" ]; then
            add_json_category "$category" "environment_variable"
            first_in_category=1
        elif [ "$OUTPUT_FORMAT" = "table" ]; then
            print_table_header "$category" "Environment Variables"
        fi
        
        for var in $vars; do
            local current_value=$(read_environment_variable "$var")
            local default_value=$(json_get_field_value "$CONFIG_FILE" "environment_variables" "$category" "$var" "default")
            local description=$(json_get_field_value "$CONFIG_FILE" "environment_variables" "$category" "$var" "description")
            
            # Use default description if empty
            if [ -z "$description" ]; then
                description="No description"
            fi
            
            if [ "$OUTPUT_FORMAT" = "json" ]; then
                add_json_property "$var" "$current_value" "$default_value" "$description" "$first_in_category"
                first_in_category=0
            elif [ "$OUTPUT_FORMAT" = "table" ]; then
                print_table_row "$var" "$current_value" "$default_value"
            elif [ "$OUTPUT_FORMAT" = "compact" ]; then
                print_compact "$var" "$current_value" "$default_value"
            fi
        done
        
        if [ "$OUTPUT_FORMAT" = "json" ]; then
            close_json_category
        fi
    done
}

# Process Android settings from JSON
process_android_settings() {
    log_verbose "Reading Android settings..."
    
    local categories=$(json_get_categories "$CONFIG_FILE" "android_specific")
    
    if [ -z "$categories" ]; then
        log_warn "No Android settings found in configuration"
        return
    fi
    
    local first_in_category=1
    
    for category in $categories; do
        # Apply category filter if specified
        if [ -n "$CATEGORY_FILTER" ] && [ "$category" != "$CATEGORY_FILTER" ]; then
            continue
        fi
        
        log_verbose "Processing Android settings category: $category"
        
        # Get all settings in this category
        local settings_keys=$(json_get_category_keys "$CONFIG_FILE" "android_specific" "$category")
        
        local has_settings=0
        for setting_key in $settings_keys; do
            has_settings=1
            break
        done
        
        if [ "$has_settings" -eq 0 ]; then
            continue
        fi
        
        # Start category output based on format
        if [ "$OUTPUT_FORMAT" = "json" ]; then
            add_json_category "$category" "android_setting"
            first_in_category=1
        elif [ "$OUTPUT_FORMAT" = "table" ]; then
            print_table_header "$category" "Android Settings"
        fi
        
        for setting_key in $settings_keys; do
            local default_value=$(json_get_field_value "$CONFIG_FILE" "android_specific" "$category" "$setting_key" "default")
            local description=$(json_get_field_value "$CONFIG_FILE" "android_specific" "$category" "$setting_key" "description")
            
            # Use default description if empty
            if [ -z "$description" ]; then
                description="No description"
            fi
            
            # Parse namespace and key from setting_key (format: settings.namespace.key)
            case "$setting_key" in
                settings.*.*)
                    local namespace=$(echo "$setting_key" | cut -d'.' -f2)
                    local key=$(echo "$setting_key" | cut -d'.' -f3-)
                    
                    if [ -n "$namespace" ] && [ -n "$key" ] && [ "$namespace" != "$key" ]; then
                        local current_value=$(read_android_setting "$namespace" "$key")
                        
                        if [ "$OUTPUT_FORMAT" = "json" ]; then
                            add_json_property "$setting_key" "$current_value" "$default_value" "$description" "$first_in_category"
                            first_in_category=0
                        elif [ "$OUTPUT_FORMAT" = "table" ]; then
                            print_table_row "$setting_key" "$current_value" "$default_value"
                        elif [ "$OUTPUT_FORMAT" = "compact" ]; then
                            print_compact "$setting_key" "$current_value" "$default_value"
                        fi
                    fi
                    ;;
            esac
        done
        
        if [ "$OUTPUT_FORMAT" = "json" ]; then
            close_json_category
        fi
    done
}

# Main function
main() {
    parse_args "$@"
    
    if [ "$OUTPUT_FORMAT" != "json" ]; then
        log_info "=========================================="
        log_info "Android Network Settings Reader"
        log_info "=========================================="
        log_info "Configuration file: $CONFIG_FILE"
        
        if [ -n "$CATEGORY_FILTER" ]; then
            log_info "Category filter: $CATEGORY_FILTER"
        fi
        
        if [ "$COMPARE_DEFAULTS" -eq 1 ]; then
            log_info "Comparing with default values"
        fi
        
        if [ "$VERBOSE" -eq 1 ]; then
            log_info "Verbose mode enabled"
        fi
        
        echo ""
    fi
    
    # Check requirements
    check_requirements
    
    # Initialize JSON output if needed
    if [ "$OUTPUT_FORMAT" = "json" ]; then
        init_json_output
    fi
    
    # Process all configuration categories
    process_system_properties
    process_kernel_parameters
    process_environment_variables
    process_android_settings
    
    # Finalize JSON output if needed
    if [ "$OUTPUT_FORMAT" = "json" ]; then
        finalize_json_output
    elif [ "$OUTPUT_FORMAT" != "compact" ]; then
        echo ""
        log_info "=========================================="
        log_info "Reading complete"
        log_info "=========================================="
    fi
}

# Run main function with all arguments
main "$@"
