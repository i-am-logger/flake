#!/usr/bin/env bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║        Building NixOS Installer ISO                      ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${BLUE}[INFO]${NC} Building installer ISO..."
echo -e "${YELLOW}This may take 10-20 minutes depending on your system${NC}"
echo ""

nix build .#installer-iso

if [[ -L result ]]; then
    ISO_PATH=$(readlink -f result)/iso/nixos-installer-*.iso
    ISO_FILE=$(ls $ISO_PATH 2>/dev/null | head -n1)
    
    if [[ -f "$ISO_FILE" ]]; then
        ISO_SIZE=$(du -h "$ISO_FILE" | cut -f1)
        echo ""
        echo -e "${GREEN}✓ ISO built successfully!${NC}"
        echo ""
        echo "Location: $ISO_FILE"
        echo "Size: $ISO_SIZE"
        echo ""
        echo -e "${BLUE}Next steps:${NC}"
        echo "1. Write to USB drive:"
        echo "   sudo dd if=$ISO_FILE of=/dev/sdX bs=4M status=progress"
        echo ""
        echo "2. Boot from USB and follow the on-screen instructions"
        echo ""
    else
        echo -e "${YELLOW}Build completed but ISO file not found in expected location${NC}"
        echo "Check ./result/iso/ directory"
    fi
else
    echo -e "${YELLOW}Build may have succeeded but result symlink not found${NC}"
fi
