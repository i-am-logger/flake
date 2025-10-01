#!/usr/bin/env bash
# Network bandwidth monitoring

# Get active network interface (prefer wifi, then ethernet)
interface=$(ip route get 1.1.1.1 2>/dev/null | grep -Po '(?<=dev )\S+' | head -1)

if [ -z "$interface" ]; then
    echo "󰈀  ↓0 B/s | ↑0 B/s"
    exit 0
fi

# Get interface type icon
if [[ "$interface" == wl* ]]; then
    icon=""
else
    icon="󰈀"
fi

# Read current stats
rx1=$(cat /sys/class/net/"$interface"/statistics/rx_bytes 2>/dev/null || echo 0)
tx1=$(cat /sys/class/net/"$interface"/statistics/tx_bytes 2>/dev/null || echo 0)

sleep 1

# Read stats again
rx2=$(cat /sys/class/net/"$interface"/statistics/rx_bytes 2>/dev/null || echo 0)
tx2=$(cat /sys/class/net/"$interface"/statistics/tx_bytes 2>/dev/null || echo 0)

# Calculate rates
rx_rate=$((rx2 - rx1))
tx_rate=$((tx2 - tx1))

# Format output
if [ $rx_rate -gt 1048576 ]; then
    rx_display="$(awk "BEGIN {printf \"%.1f\", $rx_rate/1048576}")MB/s"
elif [ $rx_rate -gt 1024 ]; then
    rx_display="$(awk "BEGIN {printf \"%.1f\", $rx_rate/1024}")KB/s"
else
    rx_display="${rx_rate}B/s"
fi

if [ $tx_rate -gt 1048576 ]; then
    tx_display="$(awk "BEGIN {printf \"%.1f\", $tx_rate/1048576}")MB/s"
elif [ $tx_rate -gt 1024 ]; then
    tx_display="$(awk "BEGIN {printf \"%.1f\", $tx_rate/1024}")KB/s"
else
    tx_display="${tx_rate}B/s"
fi

echo "$icon  󰕒$tx_display | 󰇚$rx_display"
