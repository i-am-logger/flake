#!/usr/bin/env bash
# Fix TAS2781 speaker amp on Lenovo Legion 16IRX8H
# Unbinds/rebinds the I2C device and unmutes speakers
# Run with: sudo ./fix-audio.sh

set -euo pipefail

DRIVER_PATH="/sys/bus/i2c/drivers/tas2781-hda"
DEVICE="i2c-TIAS2781:00"

if [ "$(id -u)" -ne 0 ]; then
    echo "Must run as root: sudo $0"
    exit 1
fi

echo "Unbinding TAS2781..."
echo "$DEVICE" > "$DRIVER_PATH/unbind" || true
sleep 1

echo "Rebinding TAS2781..."
echo "$DEVICE" > "$DRIVER_PATH/bind" || true
sleep 1

echo "Forcing firmware load..."
amixer -c 0 cset iface=CARD,name='Speaker Force Firmware Load' on || true

echo "Unmuting speaker..."
amixer -c 0 sset "Speaker" unmute || true

USER_ID=$(id -u "${SUDO_USER:-logger}")
echo "Restarting PipeWire..."
sudo -u "${SUDO_USER:-logger}" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
    XDG_RUNTIME_DIR="/run/user/$USER_ID" \
    systemctl --user restart pipewire pipewire-pulse wireplumber

echo "Done. Test with: speaker-test -c 2 -t sine -l 1"
