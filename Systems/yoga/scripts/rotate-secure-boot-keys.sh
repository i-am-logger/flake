#!/usr/bin/env bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Starting Secure Boot key rotation...${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root${NC}"
    exit 1
fi

# Backup existing keys
BACKUP_DIR="/persist/var/lib/sbctl/keys.backup.$(date +%Y%m%d_%H%M%S)"
echo -e "${GREEN}Creating backup of existing keys in ${BACKUP_DIR}${NC}"
mkdir -p "${BACKUP_DIR}"
cp -r /var/lib/sbctl/keys/* "${BACKUP_DIR}/"

# Verify current status before changes
echo -e "${GREEN}Current secure boot status:${NC}"
sbctl status

# Remove existing keys
echo -e "${YELLOW}Removing existing keys...${NC}"
sbctl delete-keys

# Create new keys
echo -e "${GREEN}Creating new keys...${NC}"
sbctl create-keys

# Sign all current EFI binaries
echo -e "${GREEN}Signing EFI binaries with new keys...${NC}"
sbctl sign --save /boot/EFI/nixos/kernel-*.efi

# Verify new setup
echo -e "${GREEN}Verifying new setup:${NC}"
sbctl verify

echo -e "\n${YELLOW}=== IMPORTANT: Next Steps ===${NC}"
echo -e "1. Reboot your system"
echo -e "2. Enter UEFI settings (usually F2, F12, or Del key during boot)"
echo -e "3. Go to Secure Boot settings"
echo -e "4. If needed, clear existing keys and enter Setup Mode"
echo -e "5. Enroll the new keys using: ${GREEN}sudo sbctl enroll-keys${NC}"
echo -e "6. Save and exit UEFI settings"
echo -e "\n${YELLOW}Your old keys are backed up at: ${BACKUP_DIR}${NC}"

# Ask for reboot
read -p "Would you like to reboot now? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    systemctl reboot
fi

