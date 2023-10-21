#!/usr/bin/env bash

# sd_utils.sh
# Version 0.3
# Copyright (c) 2023 Ido Samuelson
# MIT License

# Function to list available devices and their mounts
list_devices() {
    local devices="$(lsblk -d -o PATH,SIZE,VENDOR,MODEL | grep "Disk")"

    if [ -z "$devices" ]; then
        echo "No available devices"
    else
        printf "%-12s %-10s %-10s %s\n" "Device" "Size" "Vendor" "Model"
        echo "$devices" | awk '{printf "%-12s %-10s %-10s %s\n", $1, $2, $3, $4}'
        
        # Check if the --list-mounts option is provided
        if [ "$list_mounts" = true ]; then
            echo -e "\nMounts for devices:"
            echo -e "Device      Mount Point                  File System"
            while read -r device _; do
                if [ -n "$device" ]; then
                    mounts="$(grep "$device" /proc/mounts | awk '{print $2, $3}')"
                    if [ -n "$mounts" ]; then
                        while read -r mount_point file_system; do
                            printf "%-12s %-28s %-10s\n" "$device" "$mount_point" "$file_system"
                        done <<< "$mounts"
                    fi
                fi
            done <<< "$devices"
        fi
    fi
}

# Function to write an image to a destination device
write_image() {
    local image_file="$1"
    local destination_device="$2"

    if [ ! -f "$image_file" ]; then
        echo "Error: The selected image file '$image_file' does not exist."
        exit 1
    fi

    if [ ! -b "$destination_device" ]; then
        echo "Error: The specified destination device '$destination_device' does not exist or is not a block device."
        exit 1
    fi

    if ! is_device_mounted "$destination_device"; then
        echo "Error: The specified destination device '$destination_device' is not mounted."
        exit 1
    fi

    echo "Are you sure you want to write '$image_file' to '$destination_device'?"
    auto_yes

    echo "Writing '$image_file' to '$destination_device'. This may take a while..."
    sudo dd if="$image_file" of="$destination_device" bs=4M status=progress
    echo "Operation completed. '$image_file' has been written to '$destination_device'."

    flush_device "$destination_device"
    unmount_device "$destination_device"
    eject_device "$destination_device"
}

# Function to flush the device
flush_device() {
    if [ -b "$1" ]; then
        echo "Flushing '$1'..."
        sudo sync
    fi
}

# Function to unmount the device
unmount_device() {
    if [ -b "$1" ]; then
        if is_device_mounted "$1"; then
            echo "Unmounting '$1'..."
            sudo umount "$1"
        else
            echo "'$1' is not mounted."
        fi
    fi
}

# Function to eject the device
eject_device() {
    if [ -b "$1" ]; then
        echo "Ejecting '$1'..."
        sudo eject "$1"
    fi
}

# Function to check if a device is mounted
is_device_mounted() {
    if grep -qs "$1" /proc/mounts; then
        return 0  # Device is mounted
    else
        return 1  # Device is not mounted
    fi
}

# Description of the script
DESCRIPTION="This script allows you to list available devices, write an image file to a destination device, and perform additional actions on storage devices."

# Function to display usage instructions
usage() {
    echo "sd_utils.sh v0.3"
    echo "© Ido Samuelson 2023. All rights reserved."
    echo
    echo "Description:"
    echo "    $DESCRIPTION"
    echo
    echo "Usage: $0 <command> [options]"
    echo
    echo "Commands:"
    echo "    list-devices [--list-mounts]    List available devices and their mounts."
    echo "    write-image* <image_file> <destination_device> [--yes]"
    echo "    flush* <device>                  Flush a device."
    echo "    unmount* <device>                Unmount a device."
    echo "    eject* <device>                  Eject a device."
    echo
    echo "Options:"
    echo "    --help                           Show this help message."
    echo "    --yes                            Auto-approve the operation without confirmation."
    echo "    --list-mounts                    List the mounts for each device."
    echo
    echo " * require sudo privileges."
}

# Default values
yes_mode=false
list_mounts=false

# Function to automatically answer "Yes" to the confirmation question
auto_yes() {
    if [ "$yes_mode" = true ]; then
        return 0
    fi

    select yn in "Yes" "No"; do
        case $yn in
            "Yes")
                return 0
                ;;
            "No")
                echo "Operation canceled."
                exit 0
                ;;
        esac
    done
}

# Parse command-line arguments
if [ $# -eq 0 ]; then
    usage
    exit 1
fi

command="$1"
shift

case "$command" in
    "list-devices")
        while [ $# -gt 0 ]; do
            case "$1" in
                --list-mounts)
                    list_mounts=true
                    shift
                    ;;
                --help)
                    usage
                    exit 0
                    ;;
                *)
                    echo "Invalid option for 'list-devices' command: $1"
                    usage
                    exit 1
                    ;;
            esac
        done

        list_devices
        exit 0
        ;;

    "write-image")
        while [ $# -gt 0 ]; do
            case "$1" in
                --yes)
                    yes_mode=true
                    shift
                    ;;
                --help)
                    usage
                    exit 0
                    ;;
                *)
                    break
                    ;;
            esac
        done

        if [ $# -ne 2 ]; then
            usage
            exit 1
        fi

        image_file="$1"
        destination_device="$2"

        write_image "$image_file" "$destination_device"
        exit 0
        ;;

    "flush")
        if [ $# -ne 1 ]; then
            usage
            exit 1
        fi

        device="$1"
        flush_device "$device"
        exit 0
        ;;

    "unmount")
        if [ $# -ne 1 ]; then
            usage
            exit 1
        fi

        device="$1"
        unmount_device "$device"
        exit 0
        ;;

    "eject")
        if [ $# -ne 1 ]; then
            usage
            exit 1
        fi

        device="$1"
        eject_device "$device"
        exit 0
        ;;

    *)
        echo "Invalid command: $command"
        usage
        exit 1
        ;;
esac
