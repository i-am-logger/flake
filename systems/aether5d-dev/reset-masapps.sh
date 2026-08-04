#!/usr/bin/env bash
#
# Remove hand-installed Mac App Store apps so nix-darwin's `homebrew.masApps`
# installs them itself.
#
# WHY
#
# The apps in /Applications were installed by hand, are owned by root:wheel, and
# `brew bundle` reports every one of them as "Installing X has failed!" during
# activation even though `mas list` shows them and `mas install <id>` exits 0.
# Removing them lets the next switch install them through mas from scratch, which
# is the state the declaration in systems/aether5d-dev/default.nix describes.
#
# RECOVERY
#
# These are App Store purchases tied to the Apple ID. If the switch does not
# reinstall them, open the App Store and install from the Purchased list -- no
# licence or data is lost by removing the bundle. Tailscale keeps its node
# identity in ~/Library/Group Containers, which this does NOT touch, so
# reinstalling rejoins the tailnet without re-authenticating.
#
# ORDER
#
# Default is Fidelia only: it is an audio player, so a failed reinstall costs
# nothing. Confirm the switch reinstalls it before doing the other two -- pass
# `--all`, or name apps explicitly.

set -euo pipefail

DRY=0
WHICH=(fidelia)

usage() {
    cat <<'EOF'
usage: reset-masapps.sh [--dry-run] [--all | fidelia | 1password | tailscale ...]

  --dry-run   Print what would happen, change nothing.
  --all       All three. Do this only after a single app has proven the round trip.

  With no app named, acts on fidelia alone -- the safe probe.

Run WITHOUT sudo; it elevates only for the removals and will prompt.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY=1 ;;
        --all) WHICH=(fidelia 1password tailscale) ;;
        fidelia | 1password | tailscale) [[ ${WHICH[0]} == fidelia && ${#WHICH[@]} -eq 1 ]] && WHICH=(); WHICH+=("$1") ;;
        -h | --help) usage; exit 0 ;;
        *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

say() { printf '  %s\n' "$*"; }
run() { if [[ $DRY == 1 ]]; then printf '  [dry] %s\n' "$*"; else eval "$*"; fi; }
sudorun() { if [[ $DRY == 1 ]]; then printf '  [dry] sudo %s\n' "$*"; else sudo sh -c "$*"; fi; }

bundle_for() {
    case "$1" in
        fidelia) echo "/Applications/Fidelia.app.app" ;;   # doubled extension is upstream's
        1password) echo "/Applications/1Password for Safari.app" ;;
        tailscale) echo "/Applications/Tailscale.app" ;;
    esac
}

echo "== RESET MAS APPS =="
[[ $DRY == 1 ]] && say "(dry run)"

for app in "${WHICH[@]}"; do
    bundle="$(bundle_for "$app")"

    if [[ ! -d $bundle ]]; then
        say "$app: not installed, nothing to do"
        continue
    fi

    # Tailscale runs a NetworkExtension. Removing the bundle while the extension
    # is live drops the tunnel and can leave the extension registered against a
    # path that no longer exists, so quit it first and expect the tailnet to go
    # down until the reinstall.
    if [[ $app == tailscale ]] && pgrep -f 'Tailscale.app' > /dev/null; then
        say "tailscale: quitting first -- the tailnet goes DOWN until it is reinstalled"
        run "osascript -e 'tell application \"Tailscale\" to quit' 2>/dev/null || true"
        run "sleep 2"
    fi

    say "removing $bundle"
    sudorun "rm -rf '$bundle'"
done

echo
say "Next:  sudo darwin-rebuild switch --flake .#aether5d-dev \\"
say "         --override-input mynixos ~/Code/mynixos"
say ""
say "Then check they came back:"
say "  ls -d /Applications/Fidelia.app.app '/Applications/1Password for Safari.app' /Applications/Tailscale.app"
say ""
say "If the switch does NOT reinstall them, the App Store's Purchased list will."
