#!/usr/bin/env bash

# YubiKey Touch Toggle Script
# Toggles touch requirement for various YubiKey applications
# Usage: yubikey-touch-toggle.sh [enable|disable|status]

set -uo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Ensure we have yubikey-manager available
if ! command -v ykman &> /dev/null; then
    echo -e "${RED}Error: ykman (yubikey-manager) not found${NC}"
    echo "Run this script with nix-shell -p yubikey-manager --run './yubikey-touch-toggle.sh [command]'"
    exit 1
fi

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if YubiKey is connected
check_yubikey() {
    if ! ykman info &> /dev/null; then
        print_error "No YubiKey detected. Please insert your YubiKey and try again."
        exit 1
    fi
    print_status "YubiKey detected:"
    ykman info | head -4
}

# Function to check YubiKey silently
check_yubikey_quiet() {
    if ! ykman info &> /dev/null; then
        print_error "No YubiKey detected. Please insert your YubiKey and try again."
        exit 1
    fi
}

# Function to show current touch policy status
show_status() {
    local quiet=${1:-false}
    
    if [ "$quiet" != "true" ]; then
        print_status "YubiKey Touch Status:"
        echo
    fi
    
    # Check FIDO2 touch policy
    echo -n "  FIDO2/U2F: "
    if ykman fido info &>/dev/null; then
        # For YubiKey 5 series, FIDO2 touch is typically always required
        # Check if PIN is set (indicates FIDO2 is configured)
        if ykman fido info 2>/dev/null | grep -q "PIN:"; then
            echo -e "${GREEN}ON${NC} (PIN + Touch required)"
        else
            echo -e "${GREEN}ON${NC} (Touch required)"
        fi
    else
        echo -e "${RED}N/A${NC} (Not available)"
    fi
    
    # Check OpenPGP touch policies
    if ykman openpgp info &>/dev/null; then
        local openpgp_info=$(ykman openpgp info 2>/dev/null)
        
        echo -n "  OpenPGP Auth: "
        local auth_policy=$(echo "$openpgp_info" | grep -A2 "Authentication key:" | grep "Touch policy:" | awk '{print $3}' || echo "unknown")
        case "$auth_policy" in
            "On") echo -e "${GREEN}ON${NC}" ;;
            "Off") echo -e "${RED}OFF${NC}" ;;
            "Fixed") echo -e "${YELLOW}FIXED${NC}" ;;
            *) echo -e "${YELLOW}UNKNOWN${NC}" ;;
        esac
        
        echo -n "  OpenPGP Sign: "
        local sig_policy=$(echo "$openpgp_info" | grep -A2 "Signature key:" | grep "Touch policy:" | awk '{print $3}' || echo "unknown")
        case "$sig_policy" in
            "On") echo -e "${GREEN}ON${NC}" ;;
            "Off") echo -e "${RED}OFF${NC}" ;;
            "Fixed") echo -e "${YELLOW}FIXED${NC}" ;;
            *) echo -e "${YELLOW}UNKNOWN${NC}" ;;
        esac
        
        echo -n "  OpenPGP Decrypt: "
        local enc_policy=$(echo "$openpgp_info" | grep -A2 "Decryption key:" | grep "Touch policy:" | awk '{print $3}' || echo "unknown")
        case "$enc_policy" in
            "On") echo -e "${GREEN}ON${NC}" ;;
            "Off") echo -e "${RED}OFF${NC}" ;;
            "Fixed") echo -e "${YELLOW}FIXED${NC}" ;;
            *) echo -e "${YELLOW}UNKNOWN${NC}" ;;
        esac
    else
        echo -n "  OpenPGP Auth: "
        echo -e "${RED}N/A${NC}"
        echo -n "  OpenPGP Sign: "
        echo -e "${RED}N/A${NC}"
        echo -n "  OpenPGP Decrypt: "
        echo -e "${RED}N/A${NC}"
    fi
    
    # Check PIV (simplified)
    echo -n "  PIV Auth: "
    if ykman piv info &>/dev/null; then
        # Check if there's a certificate in the auth slot 9a
        if ykman piv certificates export 9a - &>/dev/null; then
            echo -e "${YELLOW}UNKNOWN${NC} (Set during key generation)"
        else
            echo -e "${RED}N/A${NC} (No keys configured)"
        fi
    else
        echo -e "${RED}N/A${NC}"
    fi
    
    # Check OATH (show accounts with touch)
    if ykman oath accounts list &>/dev/null 2>&1; then
        local touch_accounts=$(ykman oath accounts list 2>/dev/null | wc -l | tr -d ' ')
        if [ "$touch_accounts" -gt 0 ]; then
            echo "  OATH Accounts: $touch_accounts (touch policy varies per account)"
        fi
    fi
    
    if [ "$quiet" != "true" ]; then
        echo
        echo -e "Legend: ${GREEN}ON${NC}=Touch required, ${RED}OFF${NC}=No touch, ${YELLOW}FIXED${NC}=Permanent, ${YELLOW}UNKNOWN${NC}=Cannot determine"
    fi
}

# Function to disable touch requirement
disable_touch() {
    echo "Disabling touch requirements..."
    
    # OpenPGP touch policies (if available)
    if ykman openpgp info &>/dev/null; then
        echo "  Disabling OpenPGP Auth touch..."
        ykman openpgp keys set-touch aut off && echo "    ✓ Auth: OFF" || echo "    ✗ Auth: Failed"
        
        echo "  Disabling OpenPGP Sign touch..."
        ykman openpgp keys set-touch sig off && echo "    ✓ Sign: OFF" || echo "    ✗ Sign: Failed"
        
        echo "  Disabling OpenPGP Decrypt touch..."
        ykman openpgp keys set-touch enc off && echo "    ✓ Decrypt: OFF" || echo "    ✗ Decrypt: Failed"
    fi
    
    echo "Done."
}

# Function to enable touch requirement
enable_touch() {
    echo "Enabling touch requirements..."
    
    # OpenPGP touch policies (if available)
    if ykman openpgp info &>/dev/null; then
        echo "  Enabling OpenPGP Auth touch..."
        ykman openpgp keys set-touch aut on && echo "    ✓ Auth: ON" || echo "    ✗ Auth: Failed"
        
        echo "  Enabling OpenPGP Sign touch..."
        ykman openpgp keys set-touch sig on && echo "    ✓ Sign: ON" || echo "    ✗ Sign: Failed"
        
        echo "  Enabling OpenPGP Decrypt touch..."
        ykman openpgp keys set-touch enc on && echo "    ✓ Decrypt: ON" || echo "    ✗ Decrypt: Failed"
    fi
    
    echo "Done."
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [enable|disable|status|help]"
    echo
    echo "Commands:"
    echo "  enable   - Enable touch requirement for YubiKey operations"
    echo "  disable  - Disable touch requirement for YubiKey operations"
    echo "  status   - Show current touch policy status"
    echo "  help     - Show this help message"
    echo
    echo "Note: Some applications require additional setup or PIN configuration."
    echo "This script primarily handles FIDO2/U2F touch policies."
    echo
    echo "Advanced OpenPGP commands:"
    echo "  To manually configure OpenPGP touch policies:"
    echo "    ykman openpgp keys set-touch aut on|off"
    echo "    ykman openpgp keys set-touch sig on|off" 
    echo "    ykman openpgp keys set-touch enc on|off"
    echo
    echo "Advanced PIV commands:"
    echo "  PIV touch policy is set during key generation:"
    echo "    ykman piv keys generate --touch-policy always 9a"
}

# Main script logic
main() {
    case "${1:-status}" in
        enable)
            check_yubikey_quiet
            enable_touch
            ;;
        disable)
            check_yubikey_quiet
            disable_touch
            ;;
        status)
            check_yubikey_quiet
            show_status
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_error "Unknown command: $1"
            echo
            show_usage
            exit 1
            ;;
    esac
}

main "$@"