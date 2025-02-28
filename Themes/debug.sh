#!/usr/bin/env bash

# Debug LSD theme configuration
echo "LSD Configuration Location:"
ls -l ~/.config/lsd/colors.yaml
echo -e "\n--- colors.yaml Contents ---"
cat ~/.config/lsd/colors.yaml

echo -e "\n--- LSD Settings ---"
lsd --help | grep -i color
lsd --version

echo -e "\n--- Stylix Configuration ---"
nix show-config | grep stylix
