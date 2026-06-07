#!/usr/bin/env bash
# recover-session.sh — STOPGAP session recovery (no sudo, no re-login).
#
# When the per-user systemd manager (user@UID.service) is OOM-killed, the whole
# graphical-session cohort dies and `systemctl --user` is unreachable. Restarting
# the manager needs privilege we deliberately don't take. This script instead
# relaunches the cohort DIRECTLY as detached processes in the live Hyprland
# session — idempotent: it only (re)starts what's actually dead.
#
# This is a TEMPORARY tool. The proper fix is the OTP-supervision architecture:
# `vogix recover` (portable reconcile LOGIC) + mynixos (OOM-immune user@ + cgroup
# caps so the manager can never be the OOM victim). See
# project_vogix_session_reliability + the research model (supervision tree:
# one_for_one / rest_for_one / MaxR-MaxT).
set -u
uid=$(id -u)
RUNTIME=/run/user/$uid
export PATH="/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:$PATH"
export XDG_RUNTIME_DIR="$RUNTIME"
export WAYLAND_DISPLAY=wayland-1
# Derive the LIVE Hyprland instance from the newest socket dir (robust even if
# the inherited env points at a crashed instance).
export HYPRLAND_INSTANCE_SIGNATURE=$(ls -dt "$RUNTIME"/hypr/*/ 2>/dev/null | head -1 | sed 's#.*/hypr/##; s#/##')
export DBUS_SESSION_BUS_ADDRESS="unix:path=$RUNTIME/bus"
log="$HOME/.local/state/vogix/recover-session.log"
mkdir -p "$HOME/.local/state/vogix"

launch() { # pretty-name  pgrep-f-pattern  command...
  local name=$1 pat=$2; shift 2
  if pgrep -u "$uid" -f -- "$pat" >/dev/null 2>&1; then
    printf '  ok   %s (already running)\n' "$name"
  else
    setsid env XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
      HYPRLAND_INSTANCE_SIGNATURE="$HYPRLAND_INSTANCE_SIGNATURE" \
      DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" PATH="$PATH" \
      "$@" >>"$log" 2>&1 </dev/null &
    disown 2>/dev/null || true
    printf '  up   %s\n' "$name"
  fi
}

echo "recover-session: instance=$HYPRLAND_INSTANCE_SIGNATURE"
# --- input + visual surfaces (need NO dbus; talk to Hyprland over its socket) ---
launch vogix-input   'bin/vogix input'  vogix input run
launch vogix-daemon  'bin/vogix daemon' vogix daemon
launch hyprpaper     'bin/hyprpaper'    hyprpaper
launch hypridle      'bin/hypridle'     hypridle
launch waybar        'bin/waybar'       waybar
# --- audio (best-effort: works over its own sockets; wireplumber wants dbus) ---
launch pipewire      'bin/pipewire$'        pipewire
launch wireplumber   'bin/wireplumber'      wireplumber
launch pipewire-pulse 'bin/pipewire-pulse'  pipewire-pulse
# --- reset the wedged gpg-agent (OOM-killed; loops on a broken pinentry) ---
gpgconf --kill gpg-agent scdaemon 2>/dev/null && echo "  ok   gpg-agent reset"
echo "done — log: $log"
echo "NOTE: dbus-broker is NOT restored (needs the manager); tray icons + some"
echo "      IPC stay degraded until a clean re-login or the proper mynixos fix."
