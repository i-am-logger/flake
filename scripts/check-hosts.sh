#!/usr/bin/env bash
# Build every Linux host of this flake (and evaluate the Mac) against a
# candidate mynixos checkout, without touching the flake's lock: the guard
# mynixos runs before a push, so a mynixos rev that breaks a real host, at
# evaluation OR at build time, never reaches master. Evaluating alone missed
# build-only breaks (N9 took three rounds; skyspy-dev's CUDA set was never
# built before a push; row IV89).
#
#   scripts/check-hosts.sh [mynixos-path]   (default ~/Code/logger/mynixos)
#   CHECK_HOSTS_EVAL_ONLY=1 scripts/check-hosts.sh ...   evaluate only (quick, misses build breaks)
#
# The Mac (aarch64-darwin) can't be built on Linux, so it is evaluated. On
# ads-dev1 builds run on the build cores (~/Code/logger/CPU-SLICES.md).
# Exits 0 only when every host passes; each failure prints its first error
# lines (nixpkgs' "Refusing to evaluate" names the package; a build failure
# names the derivation).
set -u
mynixos=${1:-$HOME/Code/logger/mynixos}
flake=$(cd "$(dirname "$0")/.." && pwd)
override=(--override-input mynixos "path:$mynixos" --no-write-lock-file)
cores=()
[ "$(hostname)" = ads-dev1 ] && command -v taskset >/dev/null && cores=(taskset -c 16-55,80-119 nice -n 10)
fail=0
check() { # <attr> <build|eval>
  local attr=$1 how=$2 out
  if [ "$how" = build ] && [ "${CHECK_HOSTS_EVAL_ONLY:-0}" != 1 ]; then
    out=$("${cores[@]}" nix build --no-link "${override[@]}" "$flake#$attr.config.system.build.toplevel" 2>&1)
  else
    how=eval
    out=$(nix eval --raw "${override[@]}" "$flake#$attr.config.system.build.toplevel.drvPath" 2>&1)
  fi
  if [ $? -eq 0 ]; then
    echo "ok    $attr ($how)"
  else
    echo "FAIL  $attr ($how)"
    printf '%s\n' "$out" | grep -E 'error:|Refusing to evaluate|Cannot build|builder for' | head -3 | sed 's/^/      /'
    fail=1
  fi
}
check nixosConfigurations.ads-dev1 build
check nixosConfigurations.yoga build
check nixosConfigurations.skyspy-dev build
check 'darwinConfigurations."aether5d-dev"' eval
exit $fail
