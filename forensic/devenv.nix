{ pkgs
, lib
, config
, inputs
, ...
}:

{
  name = "mvt-forensics";

  packages = with pkgs; [
    libimobiledevice
    ideviceinstaller
    ifuse
    sqlite
    jq
    curl
    git
  ];

  languages.python = {
    enable = true;
    venv.enable = true;
    venv.requirements = ''
      mvt
    '';
  };

  scripts.iphone-scan.exec = ''
    set -euo pipefail

    BACKUP_DIR="./backups"
    DECRYPTED_DIR="./decrypted"
    IOC_DIR="./iocs"

    mkdir -p "$BACKUP_DIR" "$DECRYPTED_DIR" "$IOC_DIR" ./results

    echo "============================================"
    echo "  iPhone Forensic Scan"
    echo "============================================"
    echo ""

    # Step 1: Pair
    echo "=== Step 1: Pairing with iPhone ==="
    echo "Unlock your iPhone and tap 'Trust' when prompted..."
    echo ""
    idevicepair pair || {
        echo "Failed to pair. Make sure your iPhone is:"
        echo "  - Connected via USB"
        echo "  - Unlocked"
        echo "  - You tapped 'Trust This Computer'"
        exit 1
    }
    echo "Paired successfully!"
    echo ""

    # Step 2: Get device info
    UDID=$(idevice_id -l | head -1)
    if [[ -z "$UDID" ]]; then
        echo "No device found!"
        exit 1
    fi
    DEVICE_NAME=$(ideviceinfo -k DeviceName 2>/dev/null || echo "Unknown")
    echo "Found device: $DEVICE_NAME ($UDID)"
    echo ""

    # Step 3: Set encryption password
    echo "=== Step 2: Setting up encrypted backup ==="
    read -s -p "Enter backup encryption password: " BACKUP_PASSWORD
    echo ""
    read -s -p "Confirm password: " BACKUP_PASSWORD_CONFIRM
    echo ""

    if [[ "$BACKUP_PASSWORD" != "$BACKUP_PASSWORD_CONFIRM" ]]; then
        echo "Passwords don't match!"
        exit 1
    fi

    echo "Enabling backup encryption..."
    idevicebackup2 encryption on "$BACKUP_PASSWORD" 2>/dev/null || true
    echo ""

    # Step 4: Create backup
    echo "=== Step 3: Creating backup ==="
    echo "This may take 30+ minutes depending on phone size..."
    echo ""
    idevicebackup2 backup --full "$BACKUP_DIR"
    echo ""
    echo "Backup complete!"
    echo ""

    # Step 5: Download IOCs using MVT's built-in command
    echo "=== Step 4: Downloading threat indicators ==="
    mvt-ios download-iocs
    echo "IOCs downloaded."
    echo ""

    # Step 6: Decrypt backup
    echo "=== Step 5: Decrypting backup ==="
    DECRYPTED_PATH="$DECRYPTED_DIR/$UDID"
    rm -rf "$DECRYPTED_PATH"
    mkdir -p "$DECRYPTED_PATH"

    MVT_IOS_BACKUP_PASSWORD="$BACKUP_PASSWORD" mvt-ios decrypt-backup \
        -d "$DECRYPTED_PATH" \
        "$BACKUP_DIR/$UDID"
    echo "Decryption complete!"
    echo ""

    # Step 7: Run scan
    echo "=== Step 6: Scanning for spyware ==="
    RESULTS_DIR="./results/''${DEVICE_NAME// /_}_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$RESULTS_DIR"

    mvt-ios check-backup --output "$RESULTS_DIR" "$DECRYPTED_PATH"

    echo ""
    echo "============================================"
    echo "  Scan Complete: $DEVICE_NAME"
    echo "============================================"
    echo ""
    echo "Results: $RESULTS_DIR"
    echo ""
    if ls "$RESULTS_DIR"/*_detected* 1>/dev/null 2>&1; then
        echo "⚠️  DETECTIONS FOUND! Check the results directory."
    else
        echo "✓ No known threats detected."
    fi
    echo ""
    echo "Disconnect this phone and connect the next one, then run iphone-scan again."
    echo ""
  '';

  scripts.mvt-download-iocs.exec = ''
    echo "Downloading IOCs..."
    mvt-ios download-iocs
    echo "Done!"
  '';

  enterShell = ''
    echo "============================================"
    echo "  MVT - Mobile Verification Toolkit"
    echo "============================================"
    echo ""
    echo "Commands:"
    echo "  iphone-scan        - Full scan: pair, backup, and analyze"
    echo "  mvt-download-iocs  - Download latest IOCs only"
    echo ""
    echo "Just run: iphone-scan"
    echo ""
    mkdir -p ./iocs ./results ./backups ./decrypted
  '';
}
