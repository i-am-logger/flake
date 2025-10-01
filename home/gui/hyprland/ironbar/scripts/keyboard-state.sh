#!/usr/bin/env bash
# Keyboard state indicator (Caps Lock)

# Check if caps lock is on using xset or similar
if command -v xset &> /dev/null; then
    if xset q | grep "Caps Lock:.*on" > /dev/null 2>&1; then
        echo "<b><span color='red'></span></b>"
    else
        echo ""
    fi
else
    # Fallback: check using hyprctl if available
    echo ""
fi
