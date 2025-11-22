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
# backup-network-settings.sh
#
# A script to backup current network settings to a JSON file with metadata tracking
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
#   ./backup-network-settings.sh [options]
#
# Options:
#   -o, --output <path>       Output directory for backups (default: ./backups)
#   -n, --name <name>         Custom backup name (default: auto-generated timestamp)
#   -d, --description <text>  Description for this backup
#   -v, --verbose             Enable verbose output
#   -h, --help                Display this help message
#
# Requirements:
#   - read-network-settings.sh must be in the same directory
#   - json-parser.sh must be in the same directory
#   - Standard POSIX tools (awk, sed, grep, date)

# Default values
BACKUP_DIR="./backups"
BACKUP_NAME=""
DESCRIPTION=""
VERBOSE=0
METADATA_FILE="metadata.json"

# Get script directory
if command -v readlink >/dev/null 2>&1 && readlink -f "$0" >/dev/null 2>&1; then
    SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
else
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
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
backup-network-settings.sh - Backup current network settings to JSON file

Usage:
  ./backup-network-settings.sh [options]

Options:
  -o, --output <path>       Output directory for backups (default: ./backups)
  -n, --name <name>         Custom backup name (default: auto-generated timestamp)
  -d, --description <text>  Description for this backup
  -v, --verbose             Enable verbose output
  -h, --help                Display this help message

Examples:
  # Create backup with auto-generated name
  ./backup-network-settings.sh

  # Create backup with custom name and description
  ./backup-network-settings.sh -n "pre-update" -d "Before system update"

  # Create backup in custom directory
  ./backup-network-settings.sh -o /sdcard/network-backups

Requirements:
  - read-network-settings.sh in the same directory
  - Standard POSIX tools available on Android

EOF
}

# Parse arguments
parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -o|--output)
                BACKUP_DIR="$2"
                shift 2
                ;;
            -n|--name)
                BACKUP_NAME="$2"
                shift 2
                ;;
            -d|--description)
                DESCRIPTION="$2"
                shift 2
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

# Check requirements
check_requirements() {
    log_verbose "Checking requirements..."
    
    # Check for read-network-settings.sh
    if [ ! -f "$SCRIPT_DIR/read-network-settings.sh" ]; then
        log_error "read-network-settings.sh not found in $SCRIPT_DIR"
        exit 1
    fi
    
    # Check for date command
    if ! command -v date >/dev/null 2>&1; then
        log_error "date command not found"
        exit 1
    fi
    
    log_verbose "All requirements satisfied"
}

# Generate backup filename
generate_backup_name() {
    if [ -n "$BACKUP_NAME" ]; then
        echo "${BACKUP_NAME}"
    else
        # Generate timestamp-based name
        date +"%Y%m%d_%H%M%S"
    fi
}

# Create backup directory if it doesn't exist
ensure_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        log_verbose "Creating backup directory: $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR" || {
            log_error "Failed to create backup directory: $BACKUP_DIR"
            exit 1
        }
    fi
}

# Update metadata file
update_metadata() {
    local backup_file="$1"
    local backup_name="$2"
    local timestamp="$3"
    
    log_verbose "Updating metadata file..."
    
    local metadata_path="$BACKUP_DIR/$METADATA_FILE"
    
    # Create new metadata entry
    local new_entry="{
  \"name\": \"$backup_name\",
  \"file\": \"$(basename "$backup_file")\",
  \"timestamp\": \"$timestamp\",
  \"description\": \"$DESCRIPTION\",
  \"created_by\": \"backup-network-settings.sh\"
}"
    
    # If metadata file exists, append to backups array
    if [ -f "$metadata_path" ]; then
        log_verbose "Appending to existing metadata file"
        
        # Read existing metadata (simple approach for POSIX shell)
        # We'll rebuild the file with the new entry
        local temp_file="$BACKUP_DIR/.metadata.tmp"
        
        # Check if file has backups array
        if grep -q '"backups"' "$metadata_path" 2>/dev/null; then
            # Remove closing braces and add new entry
            sed '/"backups"/,/^[[:space:]]*\]/!d' "$metadata_path" | sed '$d' > "$temp_file"
            
            # Add comma if not empty array
            if ! grep -q '\[\s*$' "$temp_file" 2>/dev/null; then
                echo "," >> "$temp_file"
            fi
            
            echo "    $new_entry" >> "$temp_file"
            echo "  ]" >> "$temp_file"
            echo "}" >> "$temp_file"
            
            # Add header from original file
            sed '/"backups"/q' "$metadata_path" | sed '$d' > "$metadata_path.new"
            cat "$temp_file" >> "$metadata_path.new"
            mv "$metadata_path.new" "$metadata_path"
            rm -f "$temp_file"
        else
            # Create new structure
            cat > "$metadata_path" << EOF
{
  "version": "1.0",
  "backups": [
    $new_entry
  ]
}
EOF
        fi
    else
        # Create new metadata file
        log_verbose "Creating new metadata file"
        cat > "$metadata_path" << EOF
{
  "version": "1.0",
  "backups": [
    $new_entry
  ]
}
EOF
    fi
    
    log_verbose "Metadata updated successfully"
}

# Main function
main() {
    parse_args "$@"
    
    log_info "=========================================="
    log_info "Network Settings Backup"
    log_info "=========================================="
    
    # Check requirements
    check_requirements
    
    # Ensure backup directory exists
    ensure_backup_dir
    
    # Generate backup name
    local backup_name=$(generate_backup_name)
    local backup_file="$BACKUP_DIR/backup_${backup_name}.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%d %H:%M:%S")
    
    log_info "Backup name: $backup_name"
    log_info "Backup file: $backup_file"
    
    if [ -n "$DESCRIPTION" ]; then
        log_info "Description: $DESCRIPTION"
    fi
    
    echo ""
    
    # Read current settings using read-network-settings.sh
    log_info "Reading current network settings..."
    
    if [ "$VERBOSE" -eq 1 ]; then
        sh "$SCRIPT_DIR/read-network-settings.sh" -o json -v > "$backup_file"
    else
        sh "$SCRIPT_DIR/read-network-settings.sh" -o json 2>/dev/null > "$backup_file"
    fi
    
    if [ $? -ne 0 ]; then
        log_error "Failed to read network settings"
        rm -f "$backup_file"
        exit 1
    fi
    
    # Verify backup file was created and is not empty
    if [ ! -s "$backup_file" ]; then
        log_error "Backup file is empty or was not created"
        rm -f "$backup_file"
        exit 1
    fi
    
    log_info "Settings backed up successfully"
    
    # Update metadata
    update_metadata "$backup_file" "$backup_name" "$timestamp"
    
    echo ""
    log_info "=========================================="
    log_info "Backup complete"
    log_info "=========================================="
    log_info "Backup saved to: $backup_file"
    log_info "Metadata: $BACKUP_DIR/$METADATA_FILE"
    
    # Show backup size
    if command -v du >/dev/null 2>&1; then
        local size=$(du -h "$backup_file" 2>/dev/null | cut -f1)
        log_info "Backup size: $size"
    fi
}

# Run main
main "$@"
