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
# generic-apply-settings.sh
#
# A generic script to apply any system settings from a JSON configuration file
# Works with open-ended categories and key-value pairs
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
# Usage:
#   ./generic-apply-settings.sh [options]
#
# Options:
#   -f, --file <path>     Path to JSON configuration file (default: config.json)
#   -c, --category <name> Apply only specific category
#   -v, --verbose         Enable verbose output
#   -d, --dry-run         Show what would be applied without making changes
#   -y, --yes             Skip confirmation prompt
#   -h, --help            Display this help message

# Default values
CONFIG_FILE="config.json"
CATEGORY_FILTER=""
VERBOSE=0
DRY_RUN=0
SKIP_CONFIRMATION=0

# Get script directory
if command -v readlink >/dev/null 2>&1 && readlink -f "$0" >/dev/null 2>&1; then
    SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
else
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

# Source JSON parser from parent directory
if [ -f "$SCRIPT_DIR/../json-parser.sh" ]; then
    . "$SCRIPT_DIR/../json-parser.sh"
elif [ -f "../json-parser.sh" ]; then
    . "../json-parser.sh"
elif [ -f "./json-parser.sh" ]; then
    . "./json-parser.sh"
else
    printf "\033[0;31m[ERROR]\033[0m json-parser.sh not found\n"
    exit 1
fi

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Log functions
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

# Print help
print_help() {
    cat << EOF
generic-apply-settings.sh - Apply generic system settings from JSON configuration

Usage:
  ./generic-apply-settings.sh [options]

Options:
  -f, --file <path>     Path to JSON configuration file (default: config.json)
  -c, --category <name> Apply only specific category
  -v, --verbose         Enable verbose output
  -d, --dry-run         Show what would be applied without making changes
  -y, --yes             Skip confirmation prompt
  -h, --help            Display this help message

Examples:
  # Apply all settings from config
  ./generic-apply-settings.sh -f myconfig.json

  # Apply only system_properties category
  ./generic-apply-settings.sh -f myconfig.json -c system_properties

  # Dry-run to preview changes
  ./generic-apply-settings.sh -f myconfig.json -d -v

Configuration Format:
  {
    "categories": {
      "category_name": {
        "settings": {
          "key_name": {
            "value": "value_to_set",
            "description": "What this setting does"
          }
        }
      }
    }
  }

Supported Category Types:
  - system_properties: Android system properties (via setprop)
  - kernel_parameters: Kernel parameters (via sysctl or /proc/sys/)
  - environment_variables: Environment variables (exported)
  - android_settings: Android Settings database (via settings command)
  - custom_commands: Custom shell commands to execute
  - Any other category: Treated as generic key-value pairs

EOF
}

# Parse arguments
parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -f|--file)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -c|--category)
                CATEGORY_FILTER="$2"
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

# Check requirements
check_requirements() {
    log_verbose "Checking requirements..."
    
    # Check for standard tools
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
        exit 1
    fi
    
    # Check if config file exists
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
    
    log_verbose "All requirements satisfied"
}

# Confirm changes
confirm_changes() {
    if [ "$DRY_RUN" -eq 1 ] || [ "$SKIP_CONFIRMATION" -eq 1 ]; then
        return 0
    fi
    
    echo ""
    printf "${YELLOW}WARNING:${NC} This will apply settings from the configuration file.\n"
    printf "Configuration: %s\n" "$CONFIG_FILE"
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

# Apply system property
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
            log_warn "Failed to set property: $key"
            return 1
        fi
    else
        log_warn "setprop command not available, skipping: $key"
        return 1
    fi
}

# Apply kernel parameter
apply_kernel_parameter() {
    local path="$1"
    local value="$2"
    local description="$3"
    
    log_verbose "Applying kernel parameter: $path = $value ($description)"
    
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "[DRY-RUN] Would set kernel parameter: $path = $value"
        return 0
    fi
    
    # Try sysctl first
    local param_name=$(echo "$path" | sed 's/^\/proc\/sys\///' | tr '/' '.')
    if command -v sysctl >/dev/null 2>&1; then
        if sysctl -w "${param_name}=${value}" 2>/dev/null; then
            log_verbose "Successfully set kernel parameter via sysctl: $param_name"
            return 0
        fi
    fi
    
    # Fallback to direct write
    if [ -f "$path" ]; then
        if echo "$value" > "$path" 2>/dev/null; then
            log_verbose "Successfully set kernel parameter via file: $path"
            return 0
        else
            log_warn "Failed to write to kernel parameter: $path"
            return 1
        fi
    else
        log_warn "Kernel parameter path not found: $path"
        return 1
    fi
}

# Apply environment variable
apply_environment_variable() {
    local key="$1"
    local value="$2"
    local description="$3"
    
    log_verbose "Applying environment variable: $key = $value ($description)"
    
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "[DRY-RUN] Would set environment variable: $key = $value"
        return 0
    fi
    
    export "$key=$value"
    log_verbose "Successfully set environment variable: $key"
    return 0
}

# Apply Android setting
apply_android_setting() {
    local namespace="$1"
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
            log_warn "Failed to set Android setting: $namespace/$key"
            return 1
        fi
    else
        log_warn "settings command not available, skipping: $namespace/$key"
        return 1
    fi
}

# Execute custom command
execute_custom_command() {
    local command="$1"
    local description="$2"
    
    log_verbose "Executing custom command: $command ($description)"
    
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "[DRY-RUN] Would execute: $command"
        return 0
    fi
    
    if sh -c "$command" 2>/dev/null; then
        log_verbose "Successfully executed command"
        return 0
    else
        log_warn "Failed to execute command: $command"
        return 1
    fi
}

# Process generic category
process_category() {
    local category="$1"
    
    # Apply category filter if specified
    if [ -n "$CATEGORY_FILTER" ] && [ "$category" != "$CATEGORY_FILTER" ]; then
        return 0
    fi
    
    log_info "Processing category: $category"
    
    # Get all settings keys in this category
    # First check if it has a "settings" sub-object
    local has_settings=$(grep -A 5 "\"$category\"" "$CONFIG_FILE" | grep -c '"settings"')
    
    if [ "$has_settings" -gt 0 ]; then
        # Extract settings from category.settings
        local in_category=0
        local in_settings=0
        local current_key=""
        local current_value=""
        local current_desc=""
        local depth=0
        local settings_depth=0
        
        while IFS= read -r line; do
            # Track brace depth
            local open_braces=$(echo "$line" | grep -o '{' | wc -l)
            local close_braces=$(echo "$line" | grep -o '}' | wc -l)
            depth=$((depth + open_braces - close_braces))
            
            # Find category
            if echo "$line" | grep -q "\"$category\"" && [ "$in_category" -eq 0 ]; then
                in_category=1
                continue
            fi
            
            # Find settings within category
            if [ "$in_category" -eq 1 ] && echo "$line" | grep -q '"settings"'; then
                in_settings=1
                settings_depth=$depth
                continue
            fi
            
            # Process settings
            if [ "$in_settings" -eq 1 ]; then
                # Exit if depth decreased below settings level
                if [ "$depth" -lt "$settings_depth" ]; then
                    break
                fi
                
                # Extract key
                if echo "$line" | grep -q '^[[:space:]]*"[^"]*":[[:space:]]*{'; then
                    current_key=$(echo "$line" | sed 's/^[[:space:]]*"\([^"]*\)".*/\1/')
                fi
                
                # Extract value
                if echo "$line" | grep -q '"value"'; then
                    current_value=$(echo "$line" | sed 's/.*"value":[[:space:]]*"\([^"]*\)".*/\1/')
                fi
                
                # Extract description
                if echo "$line" | grep -q '"description"'; then
                    current_desc=$(echo "$line" | sed 's/.*"description":[[:space:]]*"\([^"]*\)".*/\1/')
                    
                    # Apply setting based on category type
                    if [ -n "$current_key" ] && [ -n "$current_value" ]; then
                        case "$category" in
                            system_properties)
                                apply_system_property "$current_key" "$current_value" "$current_desc"
                                ;;
                            kernel_parameters)
                                apply_kernel_parameter "$current_key" "$current_value" "$current_desc"
                                ;;
                            environment_variables)
                                apply_environment_variable "$current_key" "$current_value" "$current_desc"
                                ;;
                            android_settings)
                                # Parse settings.namespace.key format
                                case "$current_key" in
                                    settings.*.*)
                                        local namespace=$(echo "$current_key" | cut -d'.' -f2)
                                        local key=$(echo "$current_key" | cut -d'.' -f3-)
                                        apply_android_setting "$namespace" "$key" "$current_value" "$current_desc"
                                        ;;
                                    *)
                                        log_warn "Invalid Android setting format: $current_key"
                                        ;;
                                esac
                                ;;
                            custom_commands)
                                execute_custom_command "$current_value" "$current_desc"
                                ;;
                            *)
                                # Generic key-value pair - log it
                                log_info "Generic setting: $current_key = $current_value"
                                if [ "$DRY_RUN" -eq 0 ] && [ "$VERBOSE" -eq 1 ]; then
                                    log_verbose "Description: $current_desc"
                                fi
                                ;;
                        esac
                    fi
                    
                    # Reset for next setting
                    current_key=""
                    current_value=""
                    current_desc=""
                fi
            fi
        done < "$CONFIG_FILE"
    fi
}

# Main function
main() {
    parse_args "$@"
    
    log_info "=========================================="
    log_info "Generic Settings Application"
    log_info "=========================================="
    log_info "Configuration file: $CONFIG_FILE"
    
    if [ "$DRY_RUN" -eq 1 ]; then
        log_warn "Running in DRY-RUN mode - no changes will be made"
    fi
    
    if [ "$VERBOSE" -eq 1 ]; then
        log_info "Verbose mode enabled"
    fi
    
    if [ -n "$CATEGORY_FILTER" ]; then
        log_info "Category filter: $CATEGORY_FILTER"
    fi
    
    echo ""
    
    # Check requirements
    check_requirements
    
    echo ""
    
    # Ask for confirmation
    confirm_changes
    
    echo ""
    
    # Get all categories from config
    local categories=$(grep -E '^[[:space:]]*"[^"]+":.*{' "$CONFIG_FILE" | \
                       sed -n '/"categories"/,/^[[:space:]]*}/p' | \
                       grep -E '^[[:space:]]*"[^"]+":' | \
                       sed 's/^[[:space:]]*"\([^"]*\)".*/\1/' | \
                       grep -v "categories" | \
                       head -20)
    
    # Process each category
    for category in $categories; do
        process_category "$category"
        echo ""
    done
    
    log_info "=========================================="
    log_info "Configuration application complete"
    log_info "=========================================="
    
    if [ "$DRY_RUN" -eq 1 ]; then
        log_info "This was a dry run. Re-run without -d to apply changes."
    fi
}

# Run main
main "$@"
