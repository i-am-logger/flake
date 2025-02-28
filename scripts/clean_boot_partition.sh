#!/usr/bin/env bash

# Get the current system generation path
current_generation_path=$(readlink -f /nix/var/nix/profiles/system)
echo "Current system generation path: $current_generation_path"

# List all files in /boot/kernels
echo "Files in /boot/kernels:"
ls -l /boot/kernels

# Remove old initrd files while keeping the current one
echo "Removing old initrd files..."
for initrd in /boot/kernels/*-initrd-*; do
  # Extract the unique identifier from the initrd file name
  identifier=$(basename "$initrd" | cut -d'-' -f1)
  
  # Check if the initrd file is associated with the current generation
  if ! echo "$current_generation_path" | grep -q "$identifier"; then
    echo "Removing old initrd: $initrd"
    sudo rm "$initrd"
  else
    echo "Keeping current initrd: $initrd"
  fi
done

echo "Cleanup completed!"
