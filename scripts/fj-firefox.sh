#!/usr/bin/env bash

firejail --profile=$(nix --extra-experimental-features nix-command --extra-experimental-features flakes eval -f '<nixpkgs>' --raw 'firejail')/etc/firejail/firefox.profile firefox
