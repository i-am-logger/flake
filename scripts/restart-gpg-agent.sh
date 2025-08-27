#!/usr/bin/env bash
set -euo pipefail

echo "[restart-gpg-agent] Restarting gpg-agent..."

# Ensure no pager for systemctl
export SYSTEMD_PAGER=cat

# Set GPG_TTY when possible
if tty >/dev/null 2>&1; then
  export GPG_TTY=$(tty)
fi

# Import GUI/session env into systemd --user so gpg-agent inherits it
# This helps pinentry-gnome3 find your display and session bus
if command -v systemctl >/dev/null 2>&1; then
  # Export common display/session vars if present
  [ -n "${DISPLAY:-}" ] && export DISPLAY
  [ -n "${WAYLAND_DISPLAY:-}" ] && export WAYLAND_DISPLAY
  [ -n "${XAUTHORITY:-}" ] && export XAUTHORITY
  [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ] && export DBUS_SESSION_BUS_ADDRESS
  [ -n "${SSH_AUTH_SOCK:-}" ] && export SSH_AUTH_SOCK
  systemctl --user import-environment \
    GPG_TTY DISPLAY WAYLAND_DISPLAY XAUTHORITY DBUS_SESSION_BUS_ADDRESS SSH_AUTH_SOCK || true
fi

echo "[restart-gpg-agent] Killing gpg-agent and scdaemon..."
if command -v gpgconf >/dev/null 2>&1; then
  gpgconf --kill gpg-agent || true
  gpgconf --kill scdaemon || true
else
  echo "gpgconf not found" >&2
  exit 1
fi

# Optionally restart systemd user sockets/services (ignore failures if not present)
if command -v systemctl >/dev/null 2>&1; then
  systemctl --user restart gpg-agent.socket gpg-agent.service gpg-agent-ssh.socket gpg-agent-browser.socket gpg-agent-extra.socket >/dev/null 2>&1 || true
  # For smartcards, pcscd may be involved; try restarting it (ignore failures / permissions)
  systemctl --no-ask-password restart pcscd.socket pcscd.service >/dev/null 2>&1 || true
fi

# Relaunch gpg-agent and refresh TTY
echo "[restart-gpg-agent] Launching gpg-agent..."
gpgconf --launch gpg-agent || true

# Ensure scdaemon is reinitialized and card is detected
echo "[restart-gpg-agent] Reloading agent and scdaemon; updating startup tty..."
gpg-connect-agent reloadagent /bye >/dev/null 2>&1 || true
gpg-connect-agent scd reset /bye >/dev/null 2>&1 || true
gpg-connect-agent scd serialno /bye >/dev/null 2>&1 || true
gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1 || true

# Show sockets for convenience
AG_SSH_SOCK=$(gpgconf --list-dirs agent-ssh-socket || true)
AG_SOCK=$(gpgconf --list-dirs agent-socket || true)

if [ -n "${AG_SSH_SOCK:-}" ] && [ -S "$AG_SSH_SOCK" ]; then
  echo "[restart-gpg-agent] SSH agent socket: $AG_SSH_SOCK"
fi
if [ -n "${AG_SOCK:-}" ] && [ -S "$AG_SOCK" ]; then
  echo "[restart-gpg-agent] GPG agent socket: $AG_SOCK"
fi

echo "[restart-gpg-agent] Done."

