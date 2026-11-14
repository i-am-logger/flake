#!/usr/bin/env bash

# ads-dev1: one 8 TB WD_BLACK SN8100, addressed by-id rather than by kernel name.
# /dev/nvme0n1 is what the disk is called TODAY; adding a second NVMe renumbers
# it, and this script's whole job is to name the right disk before wiping it.
DISK="/dev/disk/by-id/nvme-WD_BLACK_SN8100_HS_8000GB_25411S800410"

if [ ! -e "$DISK" ]; then
    echo "Error: expected disk $DISK does not exist"
    echo "This machine is not ads-dev1, or the drive was replaced. Refusing to guess."
    exit 1
fi

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
"$SCRIPT_DIR/install-nixos.sh" "$DISK" "ads-dev1"
