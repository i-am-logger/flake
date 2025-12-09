#!/usr/bin/env bash
# Compare NixOS system outputs for safety validation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_section() {
    echo -e "\n${YELLOW}▶ $1${NC}"
}

# Parse arguments
MODE="${1:-current-vs-new}"
FLAKE_PATH="${2:-/etc/nixos}"

case "$MODE" in
    current-vs-new)
        print_header "Comparing Current System vs New Build (yoga)"
        CURRENT="/run/current-system"
        NEW=$(nix build --no-link --print-out-paths "$FLAKE_PATH#nixosConfigurations.yoga.config.system.build.toplevel" 2>/dev/null)
        LABEL1="CURRENT (running)"
        LABEL2="NEW (build)"
        ;;
    yoga-vs-skyspy)
        print_header "Comparing yoga vs skyspy-dev Builds"
        CURRENT=$(nix build --no-link --print-out-paths "$FLAKE_PATH#nixosConfigurations.yoga.config.system.build.toplevel" 2>/dev/null)
        NEW=$(nix build --no-link --print-out-paths "$FLAKE_PATH#nixosConfigurations.skyspy-dev.config.system.build.toplevel" 2>/dev/null)
        LABEL1="YOGA"
        LABEL2="SKYSPY-DEV"
        ;;
    *)
        echo "Usage: $0 [current-vs-new|yoga-vs-skyspy] [flake-path]"
        echo ""
        echo "Examples:"
        echo "  $0 current-vs-new        # Compare running system with new build"
        echo "  $0 yoga-vs-skyspy        # Compare yoga and skyspy-dev builds"
        exit 1
        ;;
esac

echo -e "${LABEL1}: ${GREEN}$CURRENT${NC}"
echo -e "${LABEL2}: ${GREEN}$NEW${NC}"

# Compare closure sizes
print_section "Closure Sizes"
SIZE1=$(nix path-info -Sh "$CURRENT" 2>/dev/null | awk '{print $2}')
SIZE2=$(nix path-info -Sh "$NEW" 2>/dev/null | awk '{print $2}')
echo "$LABEL1: $SIZE1"
echo "$LABEL2: $SIZE2"

# Compare systemd services
print_section "Systemd Services Comparison"
SERVICES1=$(find "$CURRENT/etc/systemd/system" -name "*.service" -type f -o -type l 2>/dev/null | sort || echo "")
SERVICES2=$(find "$NEW/etc/systemd/system" -name "*.service" -type f -o -type l 2>/dev/null | sort || echo "")

comm -3 <(basename -a $SERVICES1 2>/dev/null | sort) <(basename -a $SERVICES2 2>/dev/null | sort) > /tmp/service-diff.txt || true

if [ -s /tmp/service-diff.txt ]; then
    echo -e "${RED}Services differ:${NC}"
    while IFS= read -r line; do
        if [[ $line =~ ^[[:space:]] ]]; then
            echo -e "  ${GREEN}+ NEW:${NC} $(echo "$line" | sed 's/^[[:space:]]*//')"
        else
            echo -e "  ${RED}- REMOVED:${NC} $line"
        fi
    done < /tmp/service-diff.txt
else
    echo -e "${GREEN}✓ Identical systemd services${NC}"
fi

# Compare environment.systemPackages
print_section "System Packages Comparison"
PKGS1=$(ls "$CURRENT/sw/bin" 2>/dev/null | sort || echo "")
PKGS2=$(ls "$NEW/sw/bin" 2>/dev/null | sort || echo "")

comm -3 <(echo "$PKGS1") <(echo "$PKGS2") > /tmp/pkg-diff.txt || true

if [ -s /tmp/pkg-diff.txt ]; then
    REMOVED=$(grep -v "^[[:space:]]" /tmp/pkg-diff.txt | wc -l)
    ADDED=$(grep "^[[:space:]]" /tmp/pkg-diff.txt | wc -l)

    echo -e "${YELLOW}Changes detected: ${RED}-$REMOVED${NC} / ${GREEN}+$ADDED${NC}"

    if [ "$REMOVED" -gt 0 ]; then
        echo -e "\n${RED}Removed binaries (first 20):${NC}"
        grep -v "^[[:space:]]" /tmp/pkg-diff.txt | head -20
    fi

    if [ "$ADDED" -gt 0 ]; then
        echo -e "\n${GREEN}Added binaries (first 20):${NC}"
        grep "^[[:space:]]" /tmp/pkg-diff.txt | sed 's/^[[:space:]]*//' | head -20
    fi
else
    echo -e "${GREEN}✓ Identical system packages${NC}"
fi

# Compare /etc configuration files
print_section "Configuration Files (/etc)"
ETC1=$(find "$CURRENT/etc" -type f 2>/dev/null | sed "s|$CURRENT/etc/||" | sort || echo "")
ETC2=$(find "$NEW/etc" -type f 2>/dev/null | sed "s|$NEW/etc/||" | sort || echo "")

comm -3 <(echo "$ETC1") <(echo "$ETC2") > /tmp/etc-diff.txt || true

if [ -s /tmp/etc-diff.txt ]; then
    REMOVED=$(grep -v "^[[:space:]]" /tmp/etc-diff.txt | wc -l)
    ADDED=$(grep "^[[:space:]]" /tmp/etc-diff.txt | wc -l)

    echo -e "${YELLOW}Changes detected: ${RED}-$REMOVED${NC} / ${GREEN}+$ADDED${NC}"

    # Show critical config changes
    CRITICAL_PATTERNS="ssh|pam|sudo|network|systemd|nixos|kernel|grub|boot"

    if grep -Ev "^[[:space:]]" /tmp/etc-diff.txt | grep -E "$CRITICAL_PATTERNS" > /tmp/critical-removed.txt 2>/dev/null; then
        echo -e "\n${RED}⚠ CRITICAL files removed:${NC}"
        cat /tmp/critical-removed.txt
    fi

    if grep -E "^[[:space:]]" /tmp/etc-diff.txt | sed 's/^[[:space:]]*//' | grep -E "$CRITICAL_PATTERNS" > /tmp/critical-added.txt 2>/dev/null; then
        echo -e "\n${GREEN}CRITICAL files added:${NC}"
        cat /tmp/critical-added.txt
    fi
else
    echo -e "${GREEN}✓ Identical configuration files${NC}"
fi

# Compare kernel modules
print_section "Kernel Modules"
KERNEL1=$(basename "$(readlink "$CURRENT/kernel")" 2>/dev/null || echo "unknown")
KERNEL2=$(basename "$(readlink "$NEW/kernel")" 2>/dev/null || echo "unknown")

if [ "$KERNEL1" = "$KERNEL2" ]; then
    echo -e "${GREEN}✓ Identical kernel: $KERNEL1${NC}"
else
    echo -e "${YELLOW}Kernel changed:${NC}"
    echo "  $LABEL1: $KERNEL1"
    echo "  $LABEL2: $KERNEL2"
fi

# Use nix-diff for detailed derivation comparison
print_section "Derivation Differences (nix-diff)"
if command -v nix-diff &> /dev/null; then
    echo "Running nix-diff (this may take a moment)..."
    nix-diff "$CURRENT" "$NEW" 2>/dev/null | head -100
else
    echo -e "${YELLOW}nix-diff not available, install with: nix-env -iA nixpkgs.nix-diff${NC}"
fi

# Summary
print_header "Summary"
if [ -s /tmp/service-diff.txt ] || [ -s /tmp/pkg-diff.txt ] || [ -s /tmp/etc-diff.txt ] || [ "$KERNEL1" != "$KERNEL2" ]; then
    echo -e "${YELLOW}⚠ DIFFERENCES DETECTED${NC}"
    echo "Review the changes above before switching."

    if [ -s /tmp/critical-removed.txt ]; then
        echo -e "\n${RED}⚠ CRITICAL: Some important files were removed!${NC}"
        echo "This may indicate a regression. Investigate before deploying."
        exit 2
    fi
else
    echo -e "${GREEN}✓ SYSTEMS ARE IDENTICAL${NC}"
    echo "Safe to switch!"
fi

# Compare NixOS users
print_section "NixOS Users"
USERS1=$(grep -E "^users.users" "$CURRENT/etc/nixos/configuration.nix" 2>/dev/null | cut -d'"' -f2 | sort || \
         find "$CURRENT/etc" -name "users.nix" -exec grep -h "name =" {} \; 2>/dev/null | cut -d'"' -f2 | sort || echo "")
USERS2=$(grep -E "^users.users" "$NEW/etc/nixos/configuration.nix" 2>/dev/null | cut -d'"' -f2 | sort || \
         find "$NEW/etc" -name "users.nix" -exec grep -h "name =" {} \; 2>/dev/null | cut -d'"' -f2 | sort || echo "")

if [ -n "$USERS1" ] && [ -n "$USERS2" ]; then
    comm -3 <(echo "$USERS1") <(echo "$USERS2") > /tmp/users-diff.txt || true

    if [ -s /tmp/users-diff.txt ]; then
        echo -e "${YELLOW}User changes detected:${NC}"
        while IFS= read -r line; do
            if [[ $line =~ ^[[:space:]] ]]; then
                echo -e "  ${GREEN}+ NEW USER:${NC} $(echo "$line" | sed 's/^[[:space:]]*//')"
            else
                echo -e "  ${RED}- REMOVED USER:${NC} $line"
            fi
        done < /tmp/users-diff.txt
    else
        echo -e "${GREEN}✓ Identical user accounts${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Could not extract user list${NC}"
fi

# Compare home-manager activations
print_section "Home-Manager User Configurations"
HM1=$(find "$CURRENT/activate-user" -type f 2>/dev/null | wc -l || echo "0")
HM2=$(find "$NEW/activate-user" -type f 2>/dev/null | wc -l || echo "0")

if [ "$HM1" -gt 0 ] || [ "$HM2" -gt 0 ]; then
    echo "$LABEL1: $HM1 home-manager user(s)"
    echo "$LABEL2: $HM2 home-manager user(s)"

    if [ "$HM1" != "$HM2" ]; then
        echo -e "${YELLOW}⚠ Number of home-manager users changed${NC}"
    else
        echo -e "${GREEN}✓ Same number of home-manager users${NC}"
    fi
else
    echo -e "${YELLOW}⚠ No home-manager activations found${NC}"
fi

# Compare environment variables (system-wide)
print_section "System Environment Variables"
ENV1=$(grep -r "environment.variables" "$CURRENT/etc/nixos" 2>/dev/null | wc -l || echo "0")
ENV2=$(grep -r "environment.variables" "$NEW/etc/nixos" 2>/dev/null | wc -l || echo "0")

if [ -f "$CURRENT/etc/profile" ] && [ -f "$NEW/etc/profile" ]; then
    diff -u "$CURRENT/etc/profile" "$NEW/etc/profile" > /tmp/profile-diff.txt 2>&1 || true

    if [ -s /tmp/profile-diff.txt ]; then
        ADDED=$(grep -c "^+" /tmp/profile-diff.txt 2>/dev/null || echo "0")
        REMOVED=$(grep -c "^-" /tmp/profile-diff.txt 2>/dev/null || echo "0")
        echo -e "${YELLOW}Profile changes: ${GREEN}+$ADDED${NC} / ${RED}-$REMOVED${NC}"

        # Show important env var changes
        if grep -E "^[+-].*export (EDITOR|BROWSER|TERMINAL|SHELL|PATH)" /tmp/profile-diff.txt > /tmp/env-changes.txt 2>/dev/null; then
            echo -e "\n${YELLOW}Important environment variable changes:${NC}"
            cat /tmp/env-changes.txt
        fi
    else
        echo -e "${GREEN}✓ Identical /etc/profile${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Could not compare environment profiles${NC}"
fi

# Compare home-manager packages for primary user
print_section "Home-Manager Packages (logger)"
if [ -d "$CURRENT/home-path" ] && [ -d "$NEW/home-path" ]; then
    HMPKGS1=$(ls "$CURRENT/home-path/bin" 2>/dev/null | sort || echo "")
    HMPKGS2=$(ls "$NEW/home-path/bin" 2>/dev/null | sort || echo "")

    comm -3 <(echo "$HMPKGS1") <(echo "$HMPKGS2") > /tmp/hm-pkg-diff.txt || true

    if [ -s /tmp/hm-pkg-diff.txt ]; then
        REMOVED=$(grep -v "^[[:space:]]" /tmp/hm-pkg-diff.txt | wc -l)
        ADDED=$(grep "^[[:space:]]" /tmp/hm-pkg-diff.txt | wc -l)

        echo -e "${YELLOW}Home packages changed: ${RED}-$REMOVED${NC} / ${GREEN}+$ADDED${NC}"

        if [ "$REMOVED" -gt 0 ]; then
            echo -e "\n${RED}Removed home binaries (first 10):${NC}"
            grep -v "^[[:space:]]" /tmp/hm-pkg-diff.txt | head -10
        fi

        if [ "$ADDED" -gt 0 ]; then
            echo -e "\n${GREEN}Added home binaries (first 10):${NC}"
            grep "^[[:space:]]" /tmp/hm-pkg-diff.txt | sed 's/^[[:space:]]*//' | head -10
        fi
    else
        echo -e "${GREEN}✓ Identical home-manager packages${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Could not find home-manager paths${NC}"
fi

# Cleanup
rm -f /tmp/service-diff.txt /tmp/pkg-diff.txt /tmp/etc-diff.txt /tmp/critical-removed.txt /tmp/critical-added.txt
rm -f /tmp/users-diff.txt /tmp/profile-diff.txt /tmp/env-changes.txt /tmp/hm-pkg-diff.txt

echo ""
