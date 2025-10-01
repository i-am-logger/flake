#!/usr/bin/env bash
# Privacy indicators for screenshare and audio
output=""

# Check for screenshare (look for pipewire screenshare sessions)
if pgrep -f "pipewire.*screen" > /dev/null 2>&1; then
    output+="  "
fi

# Check for audio input (microphone)
if pamixer --source 0 --get-mute 2>/dev/null | grep -q "false"; then
    output+="  "
fi

echo "$output"
