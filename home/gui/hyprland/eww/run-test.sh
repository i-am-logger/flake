#!/usr/bin/env bash

echo "Running eww test with all dependencies..."

cd /home/logger/.config/eww

# Run the test in nix-shell with all dependencies for eww
nix-shell eww.nix --run "./test-eww.sh"
