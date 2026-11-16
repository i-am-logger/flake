#!/usr/bin/env bash
# Evaluate every host of this flake against a candidate mynixos checkout,
# without touching the flake's lock: the guard mynixos runs before a push, so
# a mynixos rev that no real host can instantiate never reaches master.
#
#   scripts/check-hosts.sh [mynixos-path]   (default ~/Code/logger/mynixos)
#
# Exits 0 only when all four hosts instantiate; each failure prints its first
# error lines (nixpkgs' "Refusing to evaluate" names the package).
set -u
mynixos=${1:-$HOME/Code/logger/mynixos}
flake=$(cd "$(dirname "$0")/.." && pwd)
override=(--override-input mynixos "path:$mynixos" --no-write-lock-file)
fail=0
for attr in \
  nixosConfigurations.ads-dev1 \
  nixosConfigurations.yoga \
  nixosConfigurations.skyspy-dev \
  'darwinConfigurations."aether5d-dev"'; do
  if out=$(nix eval --raw "${override[@]}" "$flake#$attr.config.system.build.toplevel.drvPath" 2>&1); then
    echo "ok    $attr"
  else
    echo "FAIL  $attr"
    printf '%s\n' "$out" | grep -E 'error:|Refusing to evaluate' | head -3 | sed 's/^/      /'
    fail=1
  fi
done
exit $fail
