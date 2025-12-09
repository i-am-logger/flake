#!/usr/bin/env bash
# Comprehensive script to reset and initialize YubiKey connection with GPG
# Save as ~/yubikey-reset.sh and make executable: chmod +x ~/yubikey-reset.sh

echo "Starting YubiKey reset procedure..."

# Stop all potential conflicting services
echo "Stopping GPG and smartcard services..."
gpgconf --kill all
sudo systemctl stop pcscd.socket
sudo systemctl stop pcscd.service
sleep 2

# Start services in correct order
echo "Starting smartcard service..."
sudo systemctl start pcscd.service
sleep 3

echo "Checking if YubiKey is detected by system..."
if ! lsusb | grep -i yubi > /dev/null; then
  echo "YubiKey not detected at USB level! Please check physical connection."
  echo "Try removing and reinserting the YubiKey."
  exit 1
fi

echo "Checking if YubiKey is detected by PC/SC..."
if ! pcsc_scan -n | grep -i yubi > /dev/null; then
  echo "YubiKey not detected by PC/SC! There might be an issue with pcscd."
  echo "Try rebooting your system."
  exit 1
fi

echo "Starting GPG components..."
gpg-connect-agent /bye
sleep 1

# Force scdaemon to restart and detect cards
echo "Initializing smartcard daemon..."
gpg-connect-agent "SCD RESTART" /bye
sleep 2

# Verify card status
echo "Checking YubiKey status with GPG..."
if gpg --card-status > /dev/null 2>&1; then
  echo "Success! YubiKey is now properly detected by GPG."
  gpg --card-status
else
  echo "Still having issues detecting YubiKey with GPG."
  echo "Error code: $?"
  echo "Trying alternative reset method..."
  
  # More aggressive reset
  gpgconf --kill all
  sleep 2
  
  # Try explicitly setting environment variables
  export GPG_TTY=$(tty)
  gpg-connect-agent updatestartuptty /bye
  sleep 1
  
  # Try again
  if gpg --card-status > /dev/null 2>&1; then
    echo "Success with alternative method! YubiKey is now properly detected."
    gpg --card-status
  else
    echo "Still unable to detect YubiKey with GPG."
    echo "You might need to reboot your system."
  fi
fi

echo "YubiKey reset procedure complete."
