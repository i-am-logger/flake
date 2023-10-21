#!/usr/bin/env bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <display> <scale>"
    exit 1
fi

OUTPUT_NAME = "$1"
SCALE="$2"

wlr-randr --output "$OUTPUT_NAME" --scale "$SCALE"
# out=$(wlr-randr | grep 'Scale:' | awk '{ print $2 }')

# echo $out 
