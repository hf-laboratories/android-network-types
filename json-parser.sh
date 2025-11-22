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
# json-parser.sh
#
# A lightweight JSON parser using only POSIX-compliant tools (awk, sed, grep)
# that are available by default on Android systems.
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
# This eliminates the dependency on jq which is not available by default on Android.
#
# Usage:
#   json_get_keys <json_file> <path>
#   json_get_value <json_file> <path>
#
# Example:
#   json_get_keys config.json '.categories.system_properties'
#   json_get_value config.json '.categories.system_properties.wifi."wifi.interface".default'

# Validate JSON file exists and is readable
json_validate_file() {
    local json_file="$1"
    
    if [ -z "$json_file" ]; then
        echo "Error: JSON file path not provided" >&2
        return 1
    fi
    
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    
    if [ ! -r "$json_file" ]; then
        echo "Error: JSON file not readable: $json_file" >&2
        return 1
    fi
    
    return 0
}

# Basic JSON syntax validation
json_validate_syntax() {
    local json_file="$1"
    
    # Check for balanced braces and brackets
    local open_braces=$(grep -o '{' "$json_file" | wc -l)
    local close_braces=$(grep -o '}' "$json_file" | wc -l)
    local open_brackets=$(grep -o '\[' "$json_file" | wc -l)
    local close_brackets=$(grep -o '\]' "$json_file" | wc -l)
    
    if [ "$open_braces" -ne "$close_braces" ]; then
        echo "Error: Unbalanced braces in JSON file (open: $open_braces, close: $close_braces)" >&2
        return 1
    fi
    
    if [ "$open_brackets" -ne "$close_brackets" ]; then
        echo "Error: Unbalanced brackets in JSON file (open: $open_brackets, close: $close_brackets)" >&2
        return 1
    fi
    
    # Check if file starts with { or [
    local first_char=$(grep -o '[^[:space:]]' "$json_file" | head -1)
    if [ "$first_char" != "{" ] && [ "$first_char" != "[" ]; then
        echo "Error: JSON file must start with '{' or '['" >&2
        return 1
    fi
    
    return 0
}

# Validate path format
json_validate_path() {
    local path="$1"
    
    if [ -z "$path" ]; then
        echo "Error: JSON path not provided" >&2
        return 1
    fi
    
    # Path should start with a dot or be absolute
    if ! echo "$path" | grep -qE '^\.|^[a-zA-Z]'; then
        echo "Error: Invalid JSON path format: $path" >&2
        return 1
    fi
    
    return 0
}

# Get keys from a JSON object at the specified path
# Returns one key per line
json_get_keys() {
    local json_file="$1"
    local path="$2"
    
    # Validate inputs
    if ! json_validate_file "$json_file"; then
        return 1
    fi
    
    if ! json_validate_path "$path"; then
        return 1
    fi
    
    if ! json_validate_syntax "$json_file"; then
        return 1
    fi
    
    # Convert path like '.categories.system_properties' to grep pattern
    # This is a simplified implementation for our specific JSON structure
    local pattern=$(echo "$path" | sed 's/^\.//' | sed 's/\./","/g')
    pattern="\"${pattern}\""
    
    # Extract the object at the path and get its keys
    # This uses awk to find the section and extract keys
    awk -v pattern="$pattern" '
    BEGIN {
        in_section = 0
        depth = 0
        target_depth = 0
    }
    {
        # Count braces to track depth
        for (i = 1; i <= length($0); i++) {
            c = substr($0, i, 1)
            if (c == "{") depth++
            else if (c == "}") depth--
        }
        
        # Simple key extraction for our specific JSON structure
        if ($0 ~ /"[^"]+":/ && depth > 0) {
            match($0, /"([^"]+)":/, arr)
            if (arr[1] != "" && arr[1] != "description" && arr[1] != "type" && arr[1] != "example" && arr[1] != "default" && arr[1] != "version" && arr[1] != "categories") {
                print arr[1]
            }
        }
    }
    ' "$json_file" 2>/dev/null | sort -u
    
    # Check if awk succeeded
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON file" >&2
        return 1
    fi
    
    return 0
}

# Get a value from JSON at the specified path
# Returns the value (without quotes for strings)
json_get_value() {
    local json_file="$1"
    local path="$2"
    
    # Validate inputs
    if ! json_validate_file "$json_file"; then
        return 1
    fi
    
    if ! json_validate_path "$path"; then
        return 1
    fi
    
    if ! json_validate_syntax "$json_file"; then
        return 1
    fi
    
    # Convert path like '.categories.system_properties.wifi."wifi.interface".default'
    # to a pattern we can search for
    local key=$(echo "$path" | sed 's/.*"\([^"]*\)"[^"]*$/\1/')
    local field=$(echo "$path" | sed 's/.*\.//') 
    
    # Use awk to find the value
    # This is a simplified parser for our specific JSON structure
    awk -v key="$key" -v field="$field" '
    BEGIN {
        found_key = 0
        in_object = 0
    }
    {
        # Look for the key
        if ($0 ~ "\"" key "\":") {
            found_key = 1
            in_object = 1
            next
        }
        
        # If we found the key, look for the field within its object
        if (found_key && in_object) {
            # Check if we are exiting the object
            if ($0 ~ /^[[:space:]]*}/) {
                found_key = 0
                in_object = 0
                next
            }
            
            # Look for the field
            if ($0 ~ "\"" field "\":") {
                # Extract value
                match($0, /"[^"]*":[[:space:]]*"([^"]*)"/, arr)
                if (arr[1] != "") {
                    print arr[1]
                    exit
                }
                # Handle non-string values
                match($0, /"[^"]*":[[:space:]]*([^,}]+)/, arr)
                if (arr[1] != "") {
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", arr[1])
                    print arr[1]
                    exit
                }
            }
        }
    }
    ' "$json_file" 2>/dev/null
    
    # Check if awk succeeded
    local awk_status=$?
    if [ $awk_status -ne 0 ]; then
        echo "Error: Failed to parse JSON file" >&2
        return 1
    fi
    
    return 0
}

# Simpler approach: Get all keys at a specific category level
# This works specifically with our android-network-keys.json structure
json_get_category_keys() {
    local json_file="$1"
    local category_type="$2"  # e.g., "system_properties", "kernel_parameters"
    local category_name="$3"   # e.g., "wifi", "dns"
    
    # Use grep and sed to extract keys - simpler and more reliable
    # Find the section, then extract all keys until we hit the closing brace
    sed -n "/\"$category_type\"/,/^[[:space:]]*}[[:space:]]*$/p" "$json_file" | \
    sed -n "/\"$category_name\"/,/^[[:space:]]*}[[:space:]]*$/p" | \
    grep -E '^[[:space:]]*"[^"]+":.*{' | \
    sed 's/^[[:space:]]*"\([^"]*\)".*/\1/' | \
    grep -v "^$category_name$"
}

# Get a specific field value for a key in a category
json_get_field_value() {
    local json_file="$1"
    local category_type="$2"  # e.g., "system_properties"
    local category_name="$3"   # e.g., "wifi"
    local key_name="$4"        # e.g., "wifi.interface"
    local field_name="$5"      # e.g., "default", "description"
    
    awk -v cat_type="$category_type" -v cat_name="$category_name" -v key="$key_name" -v field="$field_name" '
    BEGIN {
        in_category = 0
        in_key = 0
        depth = 0
        cat_depth = 0
        key_depth = 0
    }
    {
        # Track brace depth
        brace_count = gsub(/{/, "{", $0)
        close_count = gsub(/}/, "}", $0)
        depth += brace_count - close_count
        
        # Find category type
        if ($0 ~ "\"" cat_type "\"") {
            in_category = 1
            cat_depth = depth
            next
        }
        
        # Find category name within category type
        if (in_category == 1 && $0 ~ "\"" cat_name "\"") {
            in_category = 2
            next
        }
        
        # Find the key within category
        if (in_category == 2 && $0 ~ "\"" key "\"") {
            in_key = 1
            key_depth = depth
            next
        }
        
        # Extract field value when in the key
        if (in_key && $0 ~ "\"" field "\"") {
            # Extract string value
            if (match($0, /"[^"]*":[[:space:]]*"([^"]*)"/, arr)) {
                print arr[1]
                exit
            }
            # Extract non-string value
            if (match($0, /"[^"]*":[[:space:]]*([^,}[:space:]]+)/, arr)) {
                print arr[1]
                exit
            }
            # Empty string
            if ($0 ~ /"[^"]*":[[:space:]]*""/) {
                print ""
                exit
            }
        }
        
        # Exit conditions
        if (in_key && depth < key_depth) {
            # Did not find the field, print empty
            print ""
            exit
        }
        if (in_category && depth < cat_depth) {
            exit
        }
    }
    ' "$json_file"
}

# Get category names within a category type (e.g., wifi, dns, proxy under system_properties)
json_get_categories() {
    local json_file="$1"
    local category_type="$2"  # e.g., "system_properties", "kernel_parameters"
    
    # Find the category type section and extract only immediate child category names
    # We need to track depth to only get direct children
    awk -v cat_type="$category_type" '
    BEGIN {
        in_section = 0
        section_depth = 0
        depth = 0
    }
    {
        # Track brace depth
        brace_count = gsub(/{/, "{", $0)
        close_count = gsub(/}/, "}", $0)
        depth += brace_count - close_count
        
        # Find the category type
        if (!in_section && $0 ~ "\"" cat_type "\"") {
            in_section = 1
            section_depth = depth
            next
        }
        
        # Extract direct child categories (one level deeper than section_depth)
        if (in_section && depth == section_depth + 1) {
            if (match($0, /^[[:space:]]*"([^"]+)":/, arr)) {
                print arr[1]
            }
        }
        
        # Exit when we leave the section
        if (in_section && depth < section_depth) {
            exit
        }
    }
    ' "$json_file"
}
