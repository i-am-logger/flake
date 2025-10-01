#!/usr/bin/env bash
# Memory usage with colored indicators

mem_info=$(free | grep Mem)
total=$(echo "$mem_info" | awk '{print $2}')
used=$(echo "$mem_info" | awk '{print $3}')
percentage=$((used * 100 / total))

# Color-coded bars based on usage
if [ "$percentage" -lt 25 ]; then
    icon="<span color='#545862'>  ▁▁</span>"
elif [ "$percentage" -lt 37 ]; then
    icon="<span color='#545862'>  ▂▂</span>"
elif [ "$percentage" -lt 50 ]; then
    icon="<span color='#2aa9ff'>  ▃▃</span>"
elif [ "$percentage" -lt 62 ]; then
    icon="<span color='#2aa9ff'>  ▄▄</span>"
elif [ "$percentage" -lt 75 ]; then
    icon="<span color='#ffffa5'>  ▅▅</span>"
elif [ "$percentage" -lt 87 ]; then
    icon="<span color='#ffffa5'>  ▆▆</span>"
elif [ "$percentage" -lt 95 ]; then
    icon="<span color='#ff9977'>  ▇▇</span>"
else
    icon="<span color='#dd532e'>  ██</span>"
fi

echo "$icon $percentage%"
