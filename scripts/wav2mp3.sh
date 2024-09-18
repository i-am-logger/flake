#!/usr/bin/env bash

input_file=$1
output_file=$2

if [ ! -f "$input_file" ]; then
    echo "Error: Input file '$input_file' not found."
    exit 1
fi

if [ ! -f "$output_file" ]; then
    echo "Error: Output file '$output_file' not found."
    exit 1
fi

nix-shell -p ffmpeg --run "ffmpeg -i $input_file $output_file"

if [ $? -eq 0 ]; then
    echo "Conversion successful! Output file: $output_file"
else
    echo "Conversion failed. Please check your input file or try again."
fi
