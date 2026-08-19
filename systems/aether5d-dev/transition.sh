#!/usr/bin/env bash
# Move this Mac from its hand-built state onto the nix-darwin config.
#
#   1.  transition.sh --prepare      everything that must happen BEFORE the switch
#   2.  sudo darwin-rebuild switch --flake .#aether5d-dev
#   3.  transition.sh --cleanup      everything that can only happen AFTER it
#
# Why two phases rather than one: the imperative `nix profile` cannot be removed
# before the switch, because until the new system exists those 18 packages are
# the only tools on the machine. And $HOME/.nix-profile sits at mkOrder 800 in
# environment.profiles — ahead of /etc/profiles/per-user (900) and
# /run/current-system/sw (1000) — so until it IS removed you are still running
# the old binaries and every "did it work?" check is a lie. That single fact is
# what forces step 3 to exist separately.
#
# --prepare elevates itself for the root-owned parts and will prompt for sudo.
# Nothing is deleted without a backup or an explicit --force.
set -euo pipefail

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/pre-nix-darwin-$STAMP"
DRY=0
FORCE=0
MODE=""

usage() {
    cat <<'EOF'
usage: transition.sh (--prepare | --cleanup) [--dry-run] [--force]

  --prepare   Before `darwin-rebuild switch`. Moves aside files home-manager
              would collide with, or that would silently outrank it, and removes
              the root-owned installs the config replaces (prompts for sudo).

  --cleanup   After a switch you are happy with. Removes the imperative installs
              the config now provides and which currently SHADOW it.

  --dry-run   Print what would happen, change nothing. Needs no privileges.
  --force     Required for the few steps that cannot be undone.
EOF
}

say() { printf '  %s\n' "$*"; }
run() { if [[ $DRY == 1 ]]; then printf '  [dry] %s\n' "$*"; else eval "$@"; fi; }
sudorun() { if [[ $DRY == 1 ]]; then printf '  [dry] sudo %s\n' "$*"; else sudo sh -c "$*"; fi; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --prepare) MODE=prepare ;;
        --cleanup) MODE=cleanup ;;
        --dry-run) DRY=1 ;;
        --force) FORCE=1 ;;
        -h | --help) usage; exit 0 ;;
        *) echo "unknown flag: $1" >&2; usage; exit 2 ;;
    esac
    shift
done
[[ -n $MODE ]] || { usage; exit 2; }

# ---------------------------------------------------------------------------
prepare() {
    echo "== PREPARE (before the switch) =="
    run "mkdir -p '$BACKUP'"

    # ~/.gitconfig does NOT collide — home-manager writes ~/.config/git/config.
    # But git reads ~/.gitconfig at higher precedence, so leaving it means it
    # silently overrides everything the config sets. The one that looks fine
    # and isn't.
    if [[ -e $HOME/.gitconfig ]]; then
        say "~/.gitconfig -> backup (would silently outrank ~/.config/git/config)"
        run "mv '$HOME/.gitconfig' '$BACKUP/gitconfig'"
    fi

    # These DO collide. home-manager's backupFileExtension would handle them once,
    # but it is not idempotent: a second switch fails with "would be clobbered by
    # backing up". Moving them now sidesteps that permanently.
    for f in .zshrc .config/starship.toml .config/cava/config; do
        if [[ -e $HOME/$f ]]; then
            say "~/$f -> backup"
            run "mkdir -p '$BACKUP/$(dirname "$f")'"
            run "mv '$HOME/$f' '$BACKUP/$f'"
        fi
    done

    # --- root-owned from here ------------------------------------------------

    # Superseded by KeepingYouAwake (packaged in mynixos) and caffeinate, which
    # ships with macOS. Takes its bundled Helper login item with it.
    if [[ -d "/Applications/Jolt of Caffeine.app" ]]; then
        say "removing Jolt of Caffeine (replaced by KeepingYouAwake + caffeinate)"
        sudorun "rm -rf '/Applications/Jolt of Caffeine.app'"
    fi

    # Background Music is installed by hand; the config installs it as a Homebrew
    # cask. brew bundle would otherwise run the vendor .pkg over an install it has
    # no record of. Uninstall first so the cask owns it cleanly.
    #
    # These steps mirror the cask's own uninstall stanza exactly — launchctl,
    # pkgutil, its three delete paths, then the coreaudiod restart that its
    # uninstall_postflight_steps requires. Worth not hand-rolling: the HAL plugin
    # and the _BGMXPCHelper service account are not discoverable from the bundle.
    if [[ -d "/Applications/Background Music.app" ]]; then
        say "uninstalling hand-installed Background Music (the cask reinstalls it)"
        say "  this cuts all audio briefly while coreaudiod restarts"
        sudorun "launchctl bootout system/com.bearisdriving.BGM.XPCHelper 2>/dev/null || true"
        run "osascript -e 'tell application \"Background Music\" to quit' 2>/dev/null || true"
        sudorun "pkgutil --forget com.bearisdriving.BGM 2>/dev/null || true"
        sudorun "rm -rf '/Library/Application Support/Background Music'"
        sudorun "rm -rf '/Library/Audio/Plug-Ins/HAL/Background Music Device.driver'"
        sudorun "rm -rf '/usr/local/libexec/BGMXPCHelper.xpc'"
        sudorun "rm -rf '/Library/LaunchDaemons/com.bearisdriving.BGM.XPCHelper.plist'"
        sudorun "rm -rf '/Applications/Background Music.app'"
        # Drop the prefs too, so the reinstall starts from a clean device list
        # rather than inheriting the one that broke cava twice.
        run "rm -f '$HOME/Library/Preferences/com.bearisdriving.BGM.App.plist' || true"
        sudorun "killall coreaudiod 2>/dev/null || true"
    fi

    echo
    say "Backed up to: $BACKUP"
    echo
    if command -v darwin-rebuild > /dev/null; then
        say "Next:  sudo darwin-rebuild switch --flake .#aether5d-dev"
    else
        # First activation: darwin-rebuild does not exist yet -- it is installed
        # BY the switch. Use the copy inside the system being activated, so the
        # tool and the configuration are the same build.
        say "Next (nix-darwin is not installed yet, so bootstrap from the build):"
        say "    nix build .#darwinConfigurations.\"aether5d-dev\".system"
        say "    sudo ./result/sw/bin/darwin-rebuild switch --flake .#aether5d-dev"
        say ""
        say "  Add --override-input mynixos <path> to BOTH commands while the"
        say "  flake lock still points at a mynixos without this host's support."
    fi
    say "Then:  $0 --cleanup"
}

# ---------------------------------------------------------------------------
cleanup() {
    echo "== CLEANUP (after the switch) =="

    if [[ ! -d /run/current-system ]]; then
        echo "  refusing: /run/current-system missing — the switch has not run." >&2
        echo "  Removing the profile now would leave you with no tools." >&2
        exit 1
    fi

    # THE ONE THAT MATTERS. Until this is gone the old binaries win on PATH.
    if nix profile list 2>/dev/null | grep -q '^Name:'; then
        say "removing imperative nix profile packages (they SHADOW the config)"
        say "  reversible with: nix profile rollback"
        run "nix profile remove --all"
    else
        say "nix profile already empty"
    fi

    # Native claude-code installer. The config provides claude-code through
    # overlays/claude-code.nix, which tracks upstream's own release manifest
    # and so sits at or ahead of whatever the native installer ran — so this
    # swaps one claude on PATH for another. No version transcribed here,
    # because the number is what went stale last time. ~/.claude (your
    # history, projects, plugins) is deliberately NOT touched.
    if [[ -L $HOME/.local/bin/claude ]]; then
        say "removing native claude launcher (the config puts claude on PATH)"
        run "rm -f '$HOME/.local/bin/claude'"
    fi
    if [[ -d $HOME/.local/share/claude/versions ]]; then
        if [[ $FORCE == 1 ]]; then
            say "removing ~/.local/share/claude/versions (native installer payload)"
            run "rm -rf '$HOME/.local/share/claude/versions'"
        else
            say "~/.local/share/claude/versions kept; --force to remove"
        fi
    fi

    # Now provided by fonts.packages -> /Library/Fonts/Nix Fonts.
    if compgen -G "$HOME/Library/Fonts/FiraCode*" > /dev/null; then
        say "removing hand-copied FiraCode TTFs (duplicates fonts.packages)"
        run "rm -f '$HOME'/Library/Fonts/FiraCode*"
    fi

    # Hand-installed copies of apps the config now puts in /Applications/Nix Apps.
    for app in Discord 1Password; do
        if [[ -d "/Applications/$app.app" && -d "/Applications/Nix Apps/$app.app" ]]; then
            if [[ $FORCE == 1 ]]; then
                say "removing duplicate /Applications/$app.app (Nix Apps has it)"
                sudorun "rm -rf '/Applications/$app.app'"
            else
                say "/Applications/$app.app duplicates the Nix Apps copy; --force to remove"
            fi
        fi
    done

    echo
    say "Left alone on purpose:"
    say "  ~/.claude          your history, projects and plugins"
    say "  BGM runtime prefs  BGM owns and rewrites PreferredDeviceUIDs as"
    say "                     hardware changes — pinning it would hold only"
    say "                     until the next device event"
}

case "$MODE" in
    prepare) prepare ;;
    cleanup) cleanup ;;
esac
