#!/usr/bin/env bash

echo "Testing eww configuration in nix-shell environment..."

# Kill any existing eww processes
echo "Cleaning up any existing eww processes..."
eww kill || true
sleep 1

# Test if scripts are working
echo "Testing script dependencies..."
echo "Time script test:"
timeout 2 bash /home/logger/.config/eww/scripts/time-deflisten | head -1
echo "Volume script test:"
timeout 2 bash /home/logger/.config/eww/scripts/volume-deflisten | head -1
echo "Cava script test:"
timeout 2 bash /home/logger/.config/eww/scripts/cava-deflisten-240hz | head -3
echo "Workspace script test:"
timeout 2 bash /home/logger/.config/eww/scripts/get-workspaces | head -1
echo "Workspace monitor script test:"
timeout 2 bash /home/logger/.config/eww/scripts/hyprland-workspace-monitor | head -1

# Start eww daemon
echo "Starting eww daemon..."
eww daemon &
sleep 3

# Open the bar
echo "Opening eww bar..."
eww open bar
sleep 4

# Take screenshot of the top of the screen where the bar should be
echo "Taking screenshot..."
# Take a screenshot focusing on the top bar area (assuming 1920 width)
grim -g "0,0,1920,80" ~/eww-bar-screenshot.png

echo "Screenshot saved to ~/eww-bar-screenshot.png"

# Keep bar open for inspection
echo "Bar is now running. Press Ctrl+C to close and cleanup."
trap 'eww close bar; eww kill; exit' INT
while true; do sleep 1; done