#!/usr/bin/env bash
# CPU usage with colored indicators

cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print int(100 - $1)}')

# Color-coded bars based on usage
if [ "$cpu_usage" -lt 12 ]; then
    icon="<span color='#545862'>  ▁▁</span>"
elif [ "$cpu_usage" -lt 25 ]; then
    icon="<span color='#545862'>  ▂▂</span>"
elif [ "$cpu_usage" -lt 37 ]; then
    icon="<span color='#2aa9ff'>  ▃▃</span>"
elif [ "$cpu_usage" -lt 50 ]; then
    icon="<span color='#2aa9ff'>  ▄▄</span>"
elif [ "$cpu_usage" -lt 62 ]; then
    icon="<span color='#ffffa5'>  ▅▅</span>"
elif [ "$cpu_usage" -lt 75 ]; then
    icon="<span color='#ffffa5'>  ▆▆</span>"
elif [ "$cpu_usage" -lt 87 ]; then
    icon="<span color='#ff9977'>  ▇▇</span>"
else
    icon="<span color='#dd532e'>  ██</span>"
fi

echo "$icon ${cpu_usage}%"
