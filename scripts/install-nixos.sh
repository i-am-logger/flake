#!/usr/bin/env bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <disk_path> <system_name>"
    echo "Example: $0 /dev/nvme0n1 yoga"
    exit 1
fi

DISK_PATH="$1"
SYSTEM_NAME="$2"

if [ ! -e "$DISK_PATH" ]; then
    echo "Error: Disk path $DISK_PATH does not exist"
    exit 1
fi

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

nix run --extra-experimental-features "nix-command flakes" 'github:nix-community/disko/latest#disko-install' -- --write-efi-boot-entries --flake .#"$SYSTEM_NAME" --disk main "$DISK_PATH"
