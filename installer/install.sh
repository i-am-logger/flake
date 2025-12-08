#!/usr/bin/env bash
set -euo pipefail

# NixOS Unified Installer
# Supports: yoga (fresh install with disko), skyspy-dev (update or manual install)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

show_banner() {
    echo -e "${BLUE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║           NixOS Unified System Installer                 ║
║                                                           ║
║  Systems: yoga, skyspy-dev                                ║
║  Modes: fresh-install, update                             ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

show_usage() {
    cat << EOF
Usage: $0 [SYSTEM] [MODE]

SYSTEM:
  yoga        - Desktop system (AMD Ryzen, Gigabyte X870E)
  skyspy-dev  - Laptop system (Lenovo Legion 16IRX8H, dual-boot)

MODE:
  install     - Fresh installation OR update/repair existing system

Examples:
  $0 yoga install           # Install or update yoga (auto-detects)
  $0 skyspy-dev install     # Install or update skyspy-dev (auto-detects)

Behavior:
  - Fresh install: Automatically partitions and installs (yoga with disko)
  - Existing system: Updates configuration and repairs bootloader
  - Dual-boot (skyspy-dev): Preserves Windows, handles manual partitioning prompts
EOF
    exit 1
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

check_system_exists() {
    local system=$1
    if ! nix eval ".#nixosConfigurations.${system}" --raw 2>/dev/null >/dev/null; then
        log_error "System '${system}' not found in flake configuration"
        exit 1
    fi
}

detect_current_system() {
    if [[ -f /etc/nixos/hosts/yoga.nix ]]; then
        echo "yoga"
    elif [[ -f /etc/nixos/hosts/skyspy-dev.nix ]]; then
        echo "skyspy-dev"
    else
        echo "unknown"
    fi
}

is_nixos_installed() {
    [[ -f /etc/NIXOS ]]
}

has_boot_partition() {
    mount | grep -q '/boot'
}

fresh_install_yoga() {
    log_info "Starting fresh installation for yoga system"
    log_warn "This will DESTROY all data on /dev/nvme0n1!"
    
    read -p "Are you sure you want to continue? Type 'YES' to proceed: " confirm
    if [[ "$confirm" != "YES" ]]; then
        log_error "Installation cancelled"
        exit 1
    fi

    log_info "Step 1: Partitioning disk with disko..."
    nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
        --mode disko \
        ./Hardware/motherboards/gigabyte/x870e-aorus-elite-wifi7/disko.nix

    log_info "Step 2: Generating hardware configuration..."
    nixos-generate-config --no-filesystems --root /mnt

    log_info "Step 3: Installing NixOS..."
    nixos-install --flake ".#yoga" --root /mnt

    log_success "Installation complete!"
    log_info "Please reboot into your new system"
    read -p "Reboot now? (y/n): " reboot
    if [[ "$reboot" =~ ^[Yy]$ ]]; then
        reboot
    fi
}

fresh_install_skyspy() {
    log_info "Starting fresh installation for skyspy-dev system"
    log_warn "This is a dual-boot system - Windows partitions will be preserved"
    
    # Check if partitions exist
    if ! lsblk /dev/nvme0n1 >/dev/null 2>&1; then
        log_error "Disk /dev/nvme0n1 not found"
        exit 1
    fi

    cat << EOF

${YELLOW}Manual Partitioning Required for Dual-Boot Setup${NC}
=================================================

Please ensure you have:
1. EFI partition (typically nvme0n1p1) mounted at /mnt/boot
2. Root partition for NixOS mounted at /mnt
3. Windows partitions left untouched

Example commands:
  mount /dev/nvme0n1p5 /mnt          # Root partition
  mkdir -p /mnt/boot
  mount /dev/nvme0n1p1 /mnt/boot    # EFI partition

EOF
    
    read -p "Have you mounted the partitions? (y/n): " mounted
    if [[ ! "$mounted" =~ ^[Yy]$ ]]; then
        log_error "Please mount partitions before continuing"
        exit 1
    fi

    # Verify mounts
    if ! mountpoint -q /mnt; then
        log_error "/mnt is not mounted"
        exit 1
    fi
    if ! mountpoint -q /mnt/boot; then
        log_error "/mnt/boot is not mounted"
        exit 1
    fi

    log_info "Step 1: Generating hardware configuration..."
    nixos-generate-config --root /mnt

    log_info "Step 2: Installing NixOS..."
    nixos-install --flake ".#skyspy-dev" --root /mnt

    log_success "Installation complete!"
    log_info "Please reboot into your new system"
    read -p "Reboot now? (y/n): " reboot
    if [[ "$reboot" =~ ^[Yy]$ ]]; then
        reboot
    fi
}

update_system() {
    local system=$1
    local detected=$(detect_current_system)
    
    log_info "Updating system: ${system}"
    
    if [[ "$detected" != "unknown" && "$detected" != "$system" ]]; then
        log_warn "You're trying to install ${system} but currently running ${detected}"
        read -p "Continue anyway? (y/n): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    log_info "Step 1: Checking flake configuration..."
    check_system_exists "$system"

    log_info "Step 2: Building system configuration..."
    nixos-rebuild build --flake ".#${system}"

    log_info "Step 3: Switching to new configuration..."
    nixos-rebuild switch --flake ".#${system}"

    log_info "Step 4: Updating bootloader..."
    if has_boot_partition; then
        log_info "Bootloader will be updated as part of switch"
    else
        log_warn "No /boot partition detected - bootloader may need manual attention"
    fi

    log_success "System updated successfully!"
    log_info "Current generation: $(nixos-rebuild list-generations | tail -n 1)"
}

install_or_update() {
    local system=$1
    
    if is_nixos_installed; then
        log_info "Detected existing NixOS installation"
        update_system "$system"
    else
        log_info "No existing NixOS installation detected"
        case "$system" in
            yoga)
                fresh_install_yoga
                ;;
            skyspy-dev)
                fresh_install_skyspy
                ;;
        esac
    fi
}

# Main script
main() {
    show_banner

    # Parse arguments
    if [[ $# -eq 0 ]]; then
        show_usage
    fi

    local system=""
    local mode=""

    # Parse arguments (flexible order)
    for arg in "$@"; do
        case "$arg" in
            yoga|skyspy-dev)
                system="$arg"
                ;;
            install)
                mode="$arg"
                ;;
            -h|--help|help)
                show_usage
                ;;
            *)
                log_error "Unknown argument: $arg"
                show_usage
                ;;
        esac
    done

    # Validate arguments
    if [[ -z "$system" ]]; then
        log_error "No system specified"
        show_usage
    fi

    if [[ -z "$mode" ]]; then
        log_error "No mode specified"
        show_usage
    fi

    # Check if running as root (except for help)
    check_root

    # Execute unified install/update
    if [[ "$mode" == "install" ]]; then
        install_or_update "$system"
    else
        log_error "Invalid mode: ${mode}"
        show_usage
    fi
}

# Run main function
main "$@"
