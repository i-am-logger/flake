#!/usr/bin/env bash

# brightness.sh - A script to control laptop screen brightness
# Usage: ./brightness.sh [up|down|set] [value]
#   up: increase brightness by 10%
#   down: decrease brightness by 10%
#   set: set brightness to specific percentage (0-100)
#   max: set brightness to maximum
#   get: show current brightness percentage

# Set the brightness control file directly to Intel backlight
BACKLIGHT="/sys/class/backlight/intel_backlight"

# Check if the backlight directory exists
if [ ! -d "$BACKLIGHT" ]; then
    echo "Error: Intel backlight control directory not found."
    exit 1
fi

# Get the maximum brightness value
MAX_BRIGHTNESS=$(cat "$BACKLIGHT/max_brightness")
CURRENT_BRIGHTNESS=$(cat "$BACKLIGHT/brightness")

# Calculate current percentage
CURRENT_PCT=$((CURRENT_BRIGHTNESS * 100 / MAX_BRIGHTNESS))

# Function to set brightness
set_brightness() {
    local pct=$1
    
    # Ensure percentage is between 1 and 100 (never go to 0 to avoid black screen)
    if [ "$pct" -lt 1 ]; then
        pct=1
    elif [ "$pct" -gt 100 ]; then
        pct=100
    fi
    
    # Convert percentage to actual brightness value
    local new_brightness=$((MAX_BRIGHTNESS * pct / 100))
    
    # Use tee with sudo to write the new brightness
    echo "$new_brightness" | sudo tee "$BACKLIGHT/brightness" > /dev/null
    
    echo "Brightness set to $pct%"
}

case "$1" in
    up)
        # Increase by 10% or specified amount
        STEP=${2:-10}
        NEW_PCT=$((CURRENT_PCT + STEP))
        set_brightness $NEW_PCT
        ;;
    down)
        # Decrease by 10% or specified amount
        STEP=${2:-10}
        NEW_PCT=$((CURRENT_PCT - STEP))
        set_brightness $NEW_PCT
        ;;
    set)
        # Set to specified percentage
        if [ -z "$2" ]; then
            echo "Error: Please specify a percentage (0-100)"
            exit 1
        fi
        set_brightness $2
        ;;
    max)
        # Set to maximum brightness
        set_brightness 100
        ;;
    get)
        # Show current brightness
        echo "Current brightness: $CURRENT_PCT%"
        ;;
    *)
        echo "Usage: $0 [up|down|set|max|get] [value]"
        echo "  up: increase brightness by 10% or specified value"
        echo "  down: decrease brightness by 10% or specified value"
        echo "  set: set brightness to specific percentage (1-100)"
        echo "  max: set brightness to maximum"
        echo "  get: show current brightness percentage"
        exit 1
        ;;
esac

exit 0
