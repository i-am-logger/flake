#!/usr/bin/env bash
# gate.sh <label>: the one gate before landing a flake change, run from the working tree.
#   1. every checks.x86_64-linux.* builds
#   2. the four hosts evaluate (toplevel drvPath)
#   3. ads-dev1's toplevel builds, on the build cores (~/Code/logger/CPU-SLICES.md)
#   4. its closure diff against the toplevel the previous green gate built
# One log per run, truncated: ~/Code/logger/.build/flake-1b/gate/<label>.log; its last line is
# the verdict, "GATE: PASS" or "GATE: FAIL (<steps>)". Exits 0 only on PASS. It never switches.
set -uo pipefail
[ $# -eq 1 ] || { echo "usage: scripts/gate.sh <label>" >&2; exit 2; }
label=$1
root=$(cd "$(dirname "$0")/.." && pwd)
dir=${GATE_DIR:-$HOME/Code/logger/.build/flake-1b/gate}
mkdir -p "$dir"
log=$dir/$label.log
last=$dir/last-toplevel
cores=(taskset -c 16-55,80-119 nice -n 10)
failed=()

{
  echo "== gate $label, $(date -Is), $(git -C "$root" rev-parse --short HEAD)$(git -C "$root" diff --quiet HEAD -- . || echo '+dirty')"

  echo "-- checks"
  mapfile -t checks < <(nix eval --json "$root#checks.x86_64-linux" --apply builtins.attrNames 2>/dev/null | jq -r '.[]')
  [ ${#checks[@]} -gt 0 ] || { echo "FAIL  no checks found"; failed+=(checks); }
  for c in "${checks[@]}"; do
    if out=$("${cores[@]}" nix build --no-link --print-out-paths "$root#checks.x86_64-linux.$c" 2>&1); then
      echo "ok    $c"
    else
      echo "FAIL  $c: $(grep -m1 -E 'error:' <<<"$out" | sed 's/^ *//')"; failed+=("check:$c")
    fi
  done

  echo "-- hosts (eval)"
  for h in nixosConfigurations.ads-dev1 nixosConfigurations.yoga nixosConfigurations.skyspy-dev \
    'darwinConfigurations."aether5d-dev"'; do
    if nix eval --raw "$root#$h.config.system.build.toplevel.drvPath" >/dev/null 2>&1; then
      echo "ok    $h"
    else
      echo "FAIL  $h"; failed+=("eval:$h")
    fi
  done

  echo "-- ads-dev1 toplevel"
  if new=$("${cores[@]}" nix build --no-link --print-out-paths \
    "$root#nixosConfigurations.ads-dev1.config.system.build.toplevel" 2>&1 | tail -1) && [ -e "$new" ]; then
    echo "$new"
    echo "-- closure diff vs the previous green gate"
    old=$(cat "$last" 2>/dev/null || true)
    if [ -z "$old" ] || [ ! -e "$old" ]; then echo "(no previous green gate toplevel)"
    elif [ "$old" = "$new" ]; then echo "(identical toplevel: $old)"
    else echo "from $old"; nix store diff-closures "$old" "$new" 2>&1 | sed 's/\x1b\[[0-9;]*m//g'
    fi
  else
    echo "FAIL  ads-dev1 build: $new"; failed+=(build)
  fi

  if [ ${#failed[@]} -eq 0 ]; then
    [ -n "${new:-}" ] && echo "$new" > "$last"
    echo "GATE: PASS"
  else
    echo "GATE: FAIL (${failed[*]})"
  fi
} > "$log" 2>&1

cat "$log"
[ ${#failed[@]} -eq 0 ]
