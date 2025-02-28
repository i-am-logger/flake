#!/usr/bin/env bash

for version in $(ls /boot/kernel-* | grep -o '[0-9]*$'); do
  if [ "$version" != "$(readlink -f /nix/var/nix/profiles/system | grep -o 'system-[0-9]*' | cut -d'-' -f2)" ]; then
    sudo rm /boot/kernel-$version /boot/initrd-$version
  fi
done


# # Delete old generations and garbage collect
# echo "Deleting old generations..."
# sudo nix-env --delete-generations old
# sudo nix-collect-garbage
# sudo nix-collect-garbage -d

# # Remove dead symlinks from the nix store
# echo "Removing dead symlinks from nix store..."
# sudo nix-store --gc --print-dead

# # List all system generations
