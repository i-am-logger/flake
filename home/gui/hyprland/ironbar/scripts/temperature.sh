#!/usr/bin/env bash
# Temperature monitoring with colored indicators

# Try to get CPU temperature
if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    temp_c=$(cat /sys/class/thermal/thermal_zone0/temp)
    temp_c=$((temp_c / 1000))
    temp_f=$((temp_c * 9 / 5 + 32))
else
    # Fallback to sensors command if available
    temp_f=$(sensors 2>/dev/null | grep -i "Package id 0:" | awk '{print $4}' | sed 's/+//;s/°C//' | awk '{print int($1 * 9 / 5 + 32)}')
    if [ -z "$temp_f" ]; then
        echo " N/A"
        exit 0
    fi
fi

# Color-coded based on temperature (Fahrenheit)
if [ "$temp_f" -lt 104 ]; then
    icon="<span color='#545862'> ▁▁</span>"
elif [ "$temp_f" -lt 122 ]; then
    icon="<span color='#545862'> ▂▂</span>"
elif [ "$temp_f" -lt 140 ]; then
    icon="<span color='#545862'> ▃▃</span>"
elif [ "$temp_f" -lt 158 ]; then
    icon="<span color='#2aa9ff'> ▄▄</span>"
elif [ "$temp_f" -lt 167 ]; then
    icon="<span color='#ffffa5'> ▅▅</span>"
elif [ "$temp_f" -lt 176 ]; then
    icon="<span color='#ffffa5'> ▆▆</span>"
elif [ "$temp_f" -lt 185 ]; then
    icon="<span color='#ff9977'> ▇▇</span>"
else
    icon="<span color='#dd532e'> ██</span>"
fi

echo "$icon ${temp_f}°F"
