#!/usr/bin/env bash
# Lightweight audio visualizer using PipeWire volume levels
# Much lighter than cava, updates based on actual audio output

# Get current volume level
volume=$(pamixer --get-volume 2>/dev/null || echo 0)

# Check if audio is playing (via playerctl or pulse)
is_playing=false
if command -v playerctl &> /dev/null; then
    status=$(playerctl status 2>/dev/null)
    if [ "$status" = "Playing" ]; then
        is_playing=true
    fi
fi

# If not using playerctl, check PulseAudio/PipeWire for active sinks
if [ "$is_playing" = false ]; then
    # Check if there's active audio output
    if pactl list sink-inputs | grep -q "RUNNING"; then
        is_playing=true
    fi
fi

# Generate bars based on volume and playing state
if [ "$is_playing" = true ] && [ "$volume" -gt 0 ]; then
    # Dynamic bars that change based on volume
    bar_count=$((volume / 10))
    bars=""
    
    # Create animated effect with different heights
    for i in {1..10}; do
        if [ $i -le "$bar_count" ]; then
            # Vary height for animation effect
            rand=$((RANDOM % 3))
            case $rand in
                0) bars+="▄" ;;
                1) bars+="▆" ;;
                2) bars+="█" ;;
            esac
        else
            bars+="▁"
        fi
    done
    
    echo "$bars"
else
    # Idle state - flat bars
    echo "▁▁▁▁▁▁▁▁▁▁"
fi
