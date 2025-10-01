#!/usr/bin/env bash
# Simple weather display using wttr.in
curl -s "wttr.in/?format=%c+%t" 2>/dev/null || echo "󰅤"
