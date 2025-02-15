#!/usr/bin/env bash

PROFILE_PATH="/sys/firmware/acpi/platform_profile"
CHOICES_PATH="/sys/firmware/acpi/platform_profile_choices"

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root (use sudo)"
        exit 1
    fi
}

# Function to read available modes
get_available_modes() {
    if [ -f "$CHOICES_PATH" ]; then
        cat "$CHOICES_PATH"
    else
        echo "Error: Cannot read available modes"
        exit 1
    fi
}

# Function to get current mode
get_current_mode() {
    if [ -f "$PROFILE_PATH" ]; then
        cat "$PROFILE_PATH"
    else
        echo "Error: Cannot read current mode"
        exit 1
    fi
}

# Function to set mode
set_mode() {
    local mode="$1"
    local available_modes=$(get_available_modes)
    
    if echo "$available_modes" | tr ' ' '\n' | grep -q "^$mode$"; then
        echo "$mode" > "$PROFILE_PATH" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "Successfully set power mode to: $mode"
        else
            echo "Error: Failed to set mode. Make sure module thinkpad_acpi is loaded."
        fi
    else
        echo "Error: Invalid mode. Available modes are:"
        echo "$available_modes"
    fi
}

# Main script logic
case "$1" in
    "get")
        echo "Current power mode: $(get_current_mode)"
        ;;
    "list")
        echo "Available power modes:"
        get_available_modes
        ;;
    "set")
        if [ -z "$2" ]; then
            echo "Usage: $0 set <mode>"
            echo "Available modes:"
            get_available_modes
            exit 1
        fi
        check_root
        set_mode "$2"
        ;;
    *)
        echo "Usage: $0 {get|list|set <mode>}"
        echo "Examples:"
        echo "  $0 get          - Show current mode"
        echo "  $0 list         - List available modes"
        echo "  $0 set quiet    - Set to quiet mode"
        echo "  $0 set balanced - Set to balanced mode"
        exit 1
        ;;
esac
