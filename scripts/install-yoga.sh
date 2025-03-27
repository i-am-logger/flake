#!/usr/bin/env bash

# Check if /dev/nvme0n1 exists
if [ ! -e "/dev/nvme0n1" ]; then
    echo "Error: Expected disk /dev/nvme0n1 does not exist"
    exit 1
fi

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
"$SCRIPT_DIR/install-nixos.sh" "/dev/nvme0n1" "yoga"
