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
# restore-network-settings.sh
#
# A script to restore network settings from a backup file
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
#   ./restore-network-settings.sh [options]
#
# Options:
#   -f, --file <path>         Path to backup file to restore
#   -l, --list                List available backups
#   -n, --name <name>         Restore backup by name
#   -b, --backup-dir <path>   Backup directory (default: ./backups)
#   -y, --yes                 Skip confirmation prompt
#   -d, --dry-run             Show what would be restored without applying
#   -v, --verbose             Enable verbose output
#   -h, --help                Display this help message
#
# Requirements:
#   - Root/system permissions (for applying settings)
#   - json-parser.sh must be in the same directory
#   - Standard POSIX tools (awk, sed, grep)

# Default values
BACKUP_FILE=""
BACKUP_NAME=""
BACKUP_DIR="./backups"
LIST_BACKUPS=0
SKIP_CONFIRMATION=0
DRY_RUN=0
VERBOSE=0
METADATA_FILE="metadata.json"

# Get script directory
if command -v readlink >/dev/null 2>&1 && readlink -f "$0" >/dev/null 2>&1; then
    SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
else
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

# Source JSON parser
if [ -f "$SCRIPT_DIR/json-parser.sh" ]; then
    . "$SCRIPT_DIR/json-parser.sh"
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
CYAN='\033[0;36m'
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
restore-network-settings.sh - Restore network settings from backup

Usage:
  ./restore-network-settings.sh [options]

Options:
  -f, --file <path>         Path to backup file to restore
  -l, --list                List available backups
  -n, --name <name>         Restore backup by name
  -b, --backup-dir <path>   Backup directory (default: ./backups)
  -y, --yes                 Skip confirmation prompt
  -d, --dry-run             Show what would be restored without applying
  -v, --verbose             Enable verbose output
  -h, --help                Display this help message

Examples:
  # List available backups
  ./restore-network-settings.sh -l

  # Restore specific backup by name
  ./restore-network-settings.sh -n "20241122_063000"

  # Restore from specific file
  ./restore-network-settings.sh -f ./backups/backup_20241122_063000.json

  # Dry-run to preview restoration
  ./restore-network-settings.sh -n "pre-update" -d

Requirements:
  - Root/system permissions for applying settings
  - json-parser.sh in the same directory
  - Backup files created by backup-network-settings.sh

EOF
}

# Parse arguments
parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -f|--file)
                BACKUP_FILE="$2"
                shift 2
                ;;
            -l|--list)
                LIST_BACKUPS=1
                shift
                ;;
            -n|--name)
                BACKUP_NAME="$2"
                shift 2
                ;;
            -b|--backup-dir)
                BACKUP_DIR="$2"
                shift 2
                ;;
            -y|--yes)
                SKIP_CONFIRMATION=1
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=1
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

# List available backups
list_backups() {
    local metadata_path="$BACKUP_DIR/$METADATA_FILE"
    
    if [ ! -f "$metadata_path" ]; then
        log_warn "No backups found. Metadata file does not exist: $metadata_path"
        return 1
    fi
    
    echo ""
    printf "${CYAN}Available Backups:${NC}\n"
    printf "${CYAN}========================================${NC}\n"
    echo ""
    
    # Simple parsing of metadata file
    local in_backups=0
    local backup_count=0
    
    while IFS= read -r line; do
        if echo "$line" | grep -q '"backups"'; then
            in_backups=1
            continue
        fi
        
        if [ "$in_backups" -eq 1 ]; then
            # Extract name
            if echo "$line" | grep -q '"name"'; then
                backup_count=$((backup_count + 1))
                local name=$(echo "$line" | sed 's/.*"name":[[:space:]]*"\([^"]*\)".*/\1/')
                printf "${GREEN}%d.${NC} Name: ${YELLOW}%s${NC}\n" "$backup_count" "$name"
            fi
            
            # Extract file
            if echo "$line" | grep -q '"file"'; then
                local file=$(echo "$line" | sed 's/.*"file":[[:space:]]*"\([^"]*\)".*/\1/')
                printf "   File: %s\n" "$file"
            fi
            
            # Extract timestamp
            if echo "$line" | grep -q '"timestamp"'; then
                local timestamp=$(echo "$line" | sed 's/.*"timestamp":[[:space:]]*"\([^"]*\)".*/\1/')
                printf "   Time: %s\n" "$timestamp"
            fi
            
            # Extract description
            if echo "$line" | grep -q '"description"'; then
                local desc=$(echo "$line" | sed 's/.*"description":[[:space:]]*"\([^"]*\)".*/\1/')
                if [ -n "$desc" ]; then
                    printf "   Desc: %s\n" "$desc"
                fi
                echo ""
            fi
        fi
    done < "$metadata_path"
    
    if [ "$backup_count" -eq 0 ]; then
        log_warn "No backups found in metadata"
        return 1
    fi
    
    printf "${CYAN}========================================${NC}\n"
    log_info "Total backups: $backup_count"
    echo ""
}

# Find backup file by name
find_backup_by_name() {
    local name="$1"
    local metadata_path="$BACKUP_DIR/$METADATA_FILE"
    
    if [ ! -f "$metadata_path" ]; then
        log_error "Metadata file not found: $metadata_path"
        return 1
    fi
    
    # Search for backup with matching name
    local found_file=""
    local in_backups=0
    local current_name=""
    
    while IFS= read -r line; do
        if echo "$line" | grep -q '"backups"'; then
            in_backups=1
            continue
        fi
        
        if [ "$in_backups" -eq 1 ]; then
            if echo "$line" | grep -q '"name"'; then
                current_name=$(echo "$line" | sed 's/.*"name":[[:space:]]*"\([^"]*\)".*/\1/')
            fi
            
            if echo "$line" | grep -q '"file"' && [ "$current_name" = "$name" ]; then
                found_file=$(echo "$line" | sed 's/.*"file":[[:space:]]*"\([^"]*\)".*/\1/')
                break
            fi
        fi
    done < "$metadata_path"
    
    if [ -n "$found_file" ]; then
        echo "$BACKUP_DIR/$found_file"
        return 0
    else
        log_error "Backup not found with name: $name"
        return 1
    fi
}

# Confirm restoration
confirm_restore() {
    local backup_file="$1"
    
    if [ "$DRY_RUN" -eq 1 ] || [ "$SKIP_CONFIRMATION" -eq 1 ]; then
        return 0
    fi
    
    echo ""
    printf "${YELLOW}WARNING:${NC} This will restore network settings from backup.\n"
    printf "Current settings will be replaced with values from:\n"
    printf "  %s\n" "$backup_file"
    echo ""
    printf "Are you sure you want to continue? (y/yes or n/no): "
    
    read -r response
    
    case "$response" in
        [Yy]|[Yy][Ee][Ss])
            log_info "Proceeding with restoration..."
            return 0
            ;;
        *)
            log_info "Restoration cancelled by user."
            exit 0
            ;;
    esac
}

# Restore settings from backup
restore_settings() {
    local backup_file="$1"
    
    log_verbose "Restoring settings from: $backup_file"
    
    # Verify backup file exists and is readable
    if [ ! -f "$backup_file" ]; then
        log_error "Backup file not found: $backup_file"
        exit 1
    fi
    
    if [ ! -r "$backup_file" ]; then
        log_error "Backup file not readable: $backup_file"
        exit 1
    fi
    
    # The backup file is a JSON with network_settings containing all categories
    # We'll parse it and apply settings using setprop, sysctl, settings commands
    
    log_info "Parsing backup file..."
    
    # Extract timestamp
    local timestamp=$(grep '"timestamp"' "$backup_file" | head -1 | sed 's/.*"timestamp":[[:space:]]*"\([^"]*\)".*/\1/')
    if [ -n "$timestamp" ]; then
        log_info "Backup timestamp: $timestamp"
    fi
    
    echo ""
    
    # Process system properties
    restore_system_properties "$backup_file"
    echo ""
    
    # Process kernel parameters
    restore_kernel_parameters "$backup_file"
    echo ""
    
    # Process environment variables (note: these are session-specific)
    restore_environment_variables "$backup_file"
    echo ""
    
    # Process Android settings
    restore_android_settings "$backup_file"
}

# Restore system properties
restore_system_properties() {
    local backup_file="$1"
    
    log_info "Restoring system properties..."
    
    # Extract system property entries from JSON
    # This is a simplified approach - we look for lines with "current" field
    local in_system_props=0
    local prop_name=""
    local prop_value=""
    local count=0
    local failures=0
    
    while IFS= read -r line; do
        # Detect system property sections
        if echo "$line" | grep -q '"system_property_'; then
            in_system_props=1
            continue
        fi
        
        if [ "$in_system_props" -eq 1 ]; then
            # Check if we're leaving the section
            if echo "$line" | grep -q '^[[:space:]]*}[[:space:]]*$' && ! echo "$line" | grep -q '"'; then
                in_system_props=0
                continue
            fi
            
            # Extract property name (key before the colon and opening brace)
            if echo "$line" | grep -q '"[^"]*":[[:space:]]*{'; then
                prop_name=$(echo "$line" | sed 's/^[[:space:]]*"\([^"]*\)".*/\1/')
            fi
            
            # Extract current value
            if echo "$line" | grep -q '"current"' && [ -n "$prop_name" ]; then
                prop_value=$(echo "$line" | sed 's/.*"current":[[:space:]]*"\([^"]*\)".*/\1/')
                
                # Apply the property
                if [ -n "$prop_value" ]; then
                    count=$((count + 1))
                    
                    if [ "$DRY_RUN" -eq 1 ]; then
                        echo "[DRY-RUN] Would set property: $prop_name = $prop_value"
                    elif [ "$VERBOSE" -eq 1 ]; then
                        log_verbose "Setting property: $prop_name = $prop_value"
                        
                        if command -v setprop >/dev/null 2>&1; then
                            if ! setprop "$prop_name" "$prop_value" 2>/dev/null; then
                                log_warn "Failed to set: $prop_name"
                                failures=$((failures + 1))
                            fi
                        else
                            log_warn "setprop not available, skipping: $prop_name"
                            failures=$((failures + 1))
                        fi
                    else
                        if command -v setprop >/dev/null 2>&1; then
                            if ! setprop "$prop_name" "$prop_value" 2>/dev/null; then
                                failures=$((failures + 1))
                            fi
                        else
                            failures=$((failures + 1))
                        fi
                    fi
                fi
                
                prop_name=""
                prop_value=""
            fi
        fi
    done < "$backup_file"
    
    log_info "Processed $count system properties"
    if [ "$failures" -gt 0 ]; then
        log_warn "$failures system properties failed to apply"
    fi
}

# Restore kernel parameters
restore_kernel_parameters() {
    local backup_file="$1"
    
    log_info "Restoring kernel parameters..."
    
    local in_kernel_params=0
    local param_name=""
    local param_value=""
    local count=0
    local failures=0
    
    while IFS= read -r line; do
        if echo "$line" | grep -q '"kernel_parameter_'; then
            in_kernel_params=1
            continue
        fi
        
        if [ "$in_kernel_params" -eq 1 ]; then
            if echo "$line" | grep -q '^[[:space:]]*}[[:space:]]*$' && ! echo "$line" | grep -q '"'; then
                in_kernel_params=0
                continue
            fi
            
            if echo "$line" | grep -q '"/proc/sys/net/[^"]*":[[:space:]]*{'; then
                param_name=$(echo "$line" | sed 's/^[[:space:]]*"\([^"]*\)".*/\1/')
            fi
            
            if echo "$line" | grep -q '"current"' && [ -n "$param_name" ]; then
                param_value=$(echo "$line" | sed 's/.*"current":[[:space:]]*"\([^"]*\)".*/\1/')
                
                if [ -n "$param_value" ] && [ -f "$param_name" ]; then
                    count=$((count + 1))
                    
                    if [ "$DRY_RUN" -eq 1 ]; then
                        echo "[DRY-RUN] Would set kernel parameter: $param_name = $param_value"
                    elif [ "$VERBOSE" -eq 1 ]; then
                        log_verbose "Setting kernel parameter: $param_name = $param_value"
                        if ! echo "$param_value" > "$param_name" 2>/dev/null; then
                            log_warn "Failed to set: $param_name"
                            failures=$((failures + 1))
                        fi
                    else
                        if ! echo "$param_value" > "$param_name" 2>/dev/null; then
                            failures=$((failures + 1))
                        fi
                    fi
                fi
                
                param_name=""
                param_value=""
            fi
        fi
    done < "$backup_file"
    
    log_info "Processed $count kernel parameters"
    if [ "$failures" -gt 0 ]; then
        log_warn "$failures kernel parameters failed to apply"
    fi
}

# Restore environment variables
restore_environment_variables() {
    local backup_file="$1"
    
    log_info "Restoring environment variables..."
    log_warn "Note: Environment variables are session-specific and may not persist"
    
    local in_env_vars=0
    local var_name=""
    local var_value=""
    local count=0
    
    while IFS= read -r line; do
        if echo "$line" | grep -q '"environment_variable_'; then
            in_env_vars=1
            continue
        fi
        
        if [ "$in_env_vars" -eq 1 ]; then
            if echo "$line" | grep -q '^[[:space:]]*}[[:space:]]*$' && ! echo "$line" | grep -q '"'; then
                in_env_vars=0
                continue
            fi
            
            if echo "$line" | grep -q '"[A-Z_][^"]*":[[:space:]]*{'; then
                var_name=$(echo "$line" | sed 's/^[[:space:]]*"\([^"]*\)".*/\1/')
            fi
            
            if echo "$line" | grep -q '"current"' && [ -n "$var_name" ]; then
                var_value=$(echo "$line" | sed 's/.*"current":[[:space:]]*"\([^"]*\)".*/\1/')
                
                if [ -n "$var_value" ]; then
                    count=$((count + 1))
                    
                    if [ "$DRY_RUN" -eq 1 ]; then
                        echo "[DRY-RUN] Would set environment variable: $var_name = $var_value"
                    else
                        export "$var_name=$var_value"
                        if [ "$VERBOSE" -eq 1 ]; then
                            log_verbose "Set environment variable: $var_name"
                        fi
                    fi
                fi
                
                var_name=""
                var_value=""
            fi
        fi
    done < "$backup_file"
    
    log_info "Processed $count environment variables"
}

# Restore Android settings
restore_android_settings() {
    local backup_file="$1"
    
    log_info "Restoring Android settings..."
    
    local in_android_settings=0
    local setting_key=""
    local setting_value=""
    local count=0
    local failures=0
    
    while IFS= read -r line; do
        if echo "$line" | grep -q '"android_setting_'; then
            in_android_settings=1
            continue
        fi
        
        if [ "$in_android_settings" -eq 1 ]; then
            if echo "$line" | grep -q '^[[:space:]]*}[[:space:]]*$' && ! echo "$line" | grep -q '"'; then
                in_android_settings=0
                continue
            fi
            
            if echo "$line" | grep -q '"settings\.[^"]*":[[:space:]]*{'; then
                setting_key=$(echo "$line" | sed 's/^[[:space:]]*"\([^"]*\)".*/\1/')
            fi
            
            if echo "$line" | grep -q '"current"' && [ -n "$setting_key" ]; then
                setting_value=$(echo "$line" | sed 's/.*"current":[[:space:]]*"\([^"]*\)".*/\1/')
                
                # Parse setting key (format: settings.namespace.key)
                case "$setting_key" in
                    settings.*.*)
                        local namespace=$(echo "$setting_key" | cut -d'.' -f2)
                        local key=$(echo "$setting_key" | cut -d'.' -f3-)
                        
                        if [ -n "$namespace" ] && [ -n "$key" ] && [ -n "$setting_value" ]; then
                            count=$((count + 1))
                            
                            if [ "$DRY_RUN" -eq 1 ]; then
                                echo "[DRY-RUN] Would set Android setting: settings put $namespace $key $setting_value"
                            elif [ "$VERBOSE" -eq 1 ]; then
                                log_verbose "Setting Android setting: $namespace/$key = $setting_value"
                                
                                if command -v settings >/dev/null 2>&1; then
                                    if ! settings put "$namespace" "$key" "$setting_value" 2>/dev/null; then
                                        log_warn "Failed to set: $namespace/$key"
                                        failures=$((failures + 1))
                                    fi
                                else
                                    log_warn "settings command not available"
                                    failures=$((failures + 1))
                                fi
                            else
                                if command -v settings >/dev/null 2>&1; then
                                    if ! settings put "$namespace" "$key" "$setting_value" 2>/dev/null; then
                                        failures=$((failures + 1))
                                    fi
                                else
                                    failures=$((failures + 1))
                                fi
                            fi
                        fi
                        ;;
                esac
                
                setting_key=""
                setting_value=""
            fi
        fi
    done < "$backup_file"
    
    log_info "Processed $count Android settings"
    if [ "$failures" -gt 0 ]; then
        log_warn "$failures Android settings failed to apply"
    fi
}

# Main function
main() {
    parse_args "$@"
    
    # Handle list backups
    if [ "$LIST_BACKUPS" -eq 1 ]; then
        list_backups
        exit 0
    fi
    
    # Determine backup file to restore
    if [ -n "$BACKUP_FILE" ]; then
        # Use specified file
        log_verbose "Using specified backup file: $BACKUP_FILE"
    elif [ -n "$BACKUP_NAME" ]; then
        # Find backup by name
        log_verbose "Finding backup by name: $BACKUP_NAME"
        BACKUP_FILE=$(find_backup_by_name "$BACKUP_NAME")
        if [ $? -ne 0 ]; then
            exit 1
        fi
    else
        log_error "No backup specified. Use -f, -n, or -l option"
        print_help
        exit 1
    fi
    
    log_info "=========================================="
    log_info "Network Settings Restore"
    log_info "=========================================="
    log_info "Backup file: $BACKUP_FILE"
    
    if [ "$DRY_RUN" -eq 1 ]; then
        log_warn "Running in DRY-RUN mode - no changes will be made"
    fi
    
    # Confirm restoration
    confirm_restore "$BACKUP_FILE"
    
    echo ""
    
    # Restore settings
    restore_settings "$BACKUP_FILE"
    
    echo ""
    log_info "=========================================="
    log_info "Restoration complete"
    log_info "=========================================="
    
    if [ "$DRY_RUN" -eq 1 ]; then
        log_info "This was a dry run. Re-run without -d to apply changes."
    fi
}

# Run main
main "$@"
