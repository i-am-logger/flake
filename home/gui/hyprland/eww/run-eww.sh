#!/usr/bin/env bash

echo "Starting eww with all dependencies..."

cd /home/logger/.config/eww

# Kill any existing eww processes
eww kill 2>/dev/null || true
sleep 1

# Run eww in nix-shell with all dependencies
echo "Starting eww daemon and opening bar..."
nix-shell eww.nix --run "eww daemon & sleep 3; eww open bar"

echo "Eww bar is now running!"
echo "To close: eww close bar; eww kill"