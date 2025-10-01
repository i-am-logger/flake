#!/usr/bin/env bash
# Real-time CAVA audio visualizer for ironbar

# FIFO path for cava output
FIFO="/tmp/ironbar-cava.fifo"

# Create FIFO if it doesn't exist
if [ ! -p "$FIFO" ]; then
    mkfifo "$FIFO"
fi

# Start cava in background if not running
if ! pgrep -x "cava" > /dev/null; then
    # Create temporary cava config for raw output
    CAVA_CONFIG="/tmp/ironbar-cava-config"
    cat > "$CAVA_CONFIG" << EOF
[general]
framerate = 60
bars = 12

[input]
method = pulse
source = auto

[output]
method = raw
raw_target = $FIFO
data_format = ascii
ascii_max_range = 8
bar_delimiter = 32
frame_delimiter = 10
bit_format = 8bit

[smoothing]
noise_reduction = 0.77
EOF

    # Start cava with custom config
    cava -p "$CAVA_CONFIG" > /dev/null 2>&1 &
    sleep 0.2
fi

# Read from FIFO and format for display
if [ -p "$FIFO" ]; then
    # Read one line from FIFO (non-blocking)
    timeout 0.1 cat "$FIFO" | head -1 | while read -r line; do
        # Convert numbers to bar characters
        bars=""
        for val in $line; do
            case $val in
                0|1) bars+="▁" ;;
                2) bars+="▂" ;;
                3) bars+="▃" ;;
                4) bars+="▄" ;;
                5) bars+="▅" ;;
                6) bars+="▆" ;;
                7) bars+="▇" ;;
                *) bars+="█" ;;
            esac
        done
        echo "$bars"
    done
fi

# Fallback if no data
if [ -z "$bars" ]; then
    echo "▁▁▁▁▁▁▁▁▁▁▁▁"
fi
