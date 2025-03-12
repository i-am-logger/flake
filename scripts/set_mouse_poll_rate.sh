#!/usr/bin/env bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Function to set mouse polling rate
set_mouse_polling_rate() {
  local rate=$1
  local poll_interval_ms=$2
  local found_device=0
  
  # First method: Try finding mice through /sys/bus/usb/drivers/usbhid/
  echo "Looking for USB HID devices..."
  for device in /sys/bus/usb/drivers/usbhid/*; do
    if [[ -d "$device" && -f "$device/poll_interval" ]]; then
      device_name=$(cat "$device/product" 2>/dev/null || echo "USB HID device")
      echo "Setting $device_name to ${rate}Hz (${poll_interval_ms}ms)"
      echo "$poll_interval_ms" > "$device/poll_interval" 2>/dev/null
      
      if [ $? -eq 0 ]; then
        echo "Successfully set polling rate for $device_name"
        found_device=1
      fi
    fi
  done
  
  # Second method: Try finding mice through /sys/bus/usb/devices/
  if [ $found_device -eq 0 ]; then
    echo "Trying alternative method..."
    for device in /sys/bus/usb/devices/*; do
      if [[ -d "$device" && -f "$device/poll_interval" ]]; then
        device_name=$(cat "$device/product" 2>/dev/null || echo "USB device")
        echo "Setting $device_name to ${rate}Hz (${poll_interval_ms}ms)"
        echo "$poll_interval_ms" > "$device/poll_interval" 2>/dev/null
        
        if [ $? -eq 0 ]; then
          echo "Successfully set polling rate for $device_name"
          found_device=1
        fi
      fi
    done
  fi
  
  # Third method: Direct approach with a common path pattern
  if [ $found_device -eq 0 ]; then
    echo "Trying direct approach..."
    find /sys -name "poll_interval" 2>/dev/null | while read poll_file; do
      if [[ "$poll_file" == *"/usb/"* ]]; then
        device_dir=$(dirname "$poll_file")
        device_name=$(cat "$device_dir/product" 2>/dev/null || echo "USB device")
        echo "Setting $device_name to ${rate}Hz (${poll_interval_ms}ms)"
        echo "$poll_interval_ms" > "$poll_file" 2>/dev/null
        
        if [ $? -eq 0 ]; then
          echo "Successfully set polling rate for $device_name"
          found_device=1
        fi
      fi
    done
  fi
  
  if [ $found_device -eq 0 ]; then
    echo "No compatible USB mouse devices found or permission denied."
    echo "This might be because your mouse does not support changing the polling rate"
    echo "or the device paths in this script don't match your system's layout."
  fi
}

# Default to 1000Hz if no argument is provided
RATE=${1:-1000}

case "$RATE" in
  1000)
    set_mouse_polling_rate 1000 1
    ;;
  500)
    set_mouse_polling_rate 500 2
    ;;
  250)
    set_mouse_polling_rate 250 4
    ;;
  125)
    set_mouse_polling_rate 125 8
    ;;
  *)
    echo "Invalid rate. Please use 125, 250, 500, or 1000."
    exit 1
    ;;
esac

# Display current poll intervals
echo -e "\nCurrent poll intervals:"
find /sys -name "poll_interval" 2>/dev/null | grep -E "/usb/" | while read poll_file; do
  device_dir=$(dirname "$poll_file")
  if [ -f "$device_dir/product" ]; then
    product=$(cat "$device_dir/product" 2>/dev/null || echo "Unknown device")
    interval=$(cat "$poll_file" 2>/dev/null || echo "Unknown")
    if [[ "$interval" =~ ^[0-9]+$ ]]; then
      echo "$product: ${interval}ms ($(( 1000 / interval ))Hz)"
    else
      echo "$product: Unable to read interval"
    fi
  fi
done
