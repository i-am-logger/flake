# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a NixOS configuration repository that uses a custom typed functional DSL called `mynixos` (located at `/home/logger/Code/github/logger/mynixos`). The configuration is managed as a flake and uses the `my.*` namespace for system configuration.

## Architecture

### Two-Repository Structure

1. **mynixos** (`/home/logger/Code/github/logger/mynixos`) - Generic typed DSL
   - Provides type constructors and the `my.*` options namespace
   - Defines generic hardware profiles, features, and apps
   - Implements modules in `modules/` directory
   - Exposes `mynixos.lib.mkSystem` for building NixOS configurations

2. **This repository** (`/etc/nixos`) - Personal system configurations
   - Uses mynixos types to define personal data and system configs
   - Contains system-specific configurations in `systems/`
   - Manages personal secrets (referenced but not included)

### Directory Structure

```
/etc/nixos/
├── systems/           # Per-host configurations
│   ├── yoga/          # Desktop workstation (Gigabyte X870E)
│   ├── skyspy-dev/    # Laptop (Lenovo Legion 16IRX8H)
│   └── ARCHITECTURE.md
├── users/
│   └── logger/        # User account definition + avatar
├── lib/               # Personal user definitions (myLib)
├── themes/            # Stylix theming configurations
├── home/              # Home-manager packages
├── scripts/           # Helper scripts
├── docs/              # Documentation
└── flake.nix          # Main flake entry point
```

### Configuration Pattern

System configurations use `mynixos.lib.mkSystem` with this structure:

```nix
mynixos.lib.mkSystem {
  hostname = "...";
  users = [ myLib.users.logger ];  # From /etc/nixos/lib/users.nix
  hardware = [ mynixos.hardware.<type>.<model> ];

  my = {
    features = { ... };      # Feature bundles from mynixos
    apps = { ... };          # Application configs
    users.<name> = { ... };  # User data for mynixos features
    # ... other mynixos options
  };

  extraModules = [ ];        # Optional system-specific modules
}
```

### Key Concepts

- **mynixos features**: Composable feature bundles (security, graphical, ai, development, etc.)
- **Hardware profiles**: Pre-configured hardware modules from mynixos (motherboards, laptops)
- **User separation**: NixOS user created by `myLib.users.logger`, while `my.users.logger` provides data for mynixos features
- **Opinionated defaults**: mynixos provides defaults; systems only override what's needed

## Common Commands

### Building and Switching

```bash
# RECOMMENDED: Auto-detect hostname and switch
cd /etc/nixos && sudo nixos-rebuild switch --flake .#

# Test configuration WITHOUT creating bootloader entry (ALWAYS test first!)
cd /etc/nixos && sudo nixos-rebuild test --flake .#

# Build without activating (check for errors)
cd /etc/nixos && sudo nixos-rebuild build --flake .#

# Build for specific host (when not on target machine)
sudo nixos-rebuild switch --flake /etc/nixos#yoga
sudo nixos-rebuild switch --flake /etc/nixos#skyspy-dev
```

**Important**: Always run `test` before `switch` to catch issues without committing to bootloader.

### Validation and Testing

```bash
# Check flake evaluates correctly (run before committing)
nix flake check /etc/nixos

# Show flake outputs
nix flake show /etc/nixos

# Evaluate specific configuration
nix eval /etc/nixos#nixosConfigurations.yoga.config.system.build.toplevel

# Check system closure size
nix path-info -Sh /run/current-system
```

### Formatting

```bash
# Format all Nix files (run before committing)
nix fmt /etc/nixos
```

### Updating Dependencies

```bash
# Update mynixos dependency only
cd /etc/nixos && nix flake lock --update-input mynixos

# Update all inputs
cd /etc/nixos && nix flake update

# Check current mynixos version
nix flake metadata /etc/nixos
```

### Installer ISO

```bash
# Build custom installer ISO
nix build /etc/nixos#installer-iso
```

## System Hosts

### yoga
- **Hardware**: Gigabyte X870E AORUS Elite WiFi7 (AMD desktop)
- **Features**: Full desktop with AI (Ollama), secure boot, YubiKey, K3s, streaming
- **Storage**: Disko-managed with dedicated /persist partition
- **Notable**: Primary development workstation with GPU acceleration

### skyspy-dev
- **Hardware**: Lenovo Legion 16IRX8H (Intel laptop)
- **Features**: Dual-boot with Windows, development environment, streaming
- **Storage**: Impermanence via tmpfs (no dedicated partition)
- **Notable**: AI disabled, Windows mount at `/home/logger/mnt/windows`

## Feature System

All features are configured via `my.features.<feature>` from mynixos:

- **system**: Core system utilities, XDG, Nix settings
- **security**: Secure boot, YubiKey, audit rules
- **graphical**: Hyprland, VSCode, browser, webapps
- **development**: Docker, direnv, binfmt, AppImage support
- **ai**: Ollama with ROCm GPU support, MCP servers
- **streaming**: OBS Studio, StreamDeck, v4l2loopback
- **github-runner**: Self-hosted GitHub Actions runners on K3s
- **performance**: zram, vmtouch caching
- **motd**: Custom message of the day

## Personal Data Locations

- **Secrets**: `/home/logger/.secrets/` (not in git)
- **YubiKey public keys**: `/etc/nixos/users/logger/yubikey*.asc`
- **User avatar**: `/etc/nixos/users/logger/avatar.png`
- **Impermanence**: System clones `git@github.com:i-am-logger/flake.git` to `/persist/etc/nixos`

## Development Workflow

1. Edit system configuration in `/etc/nixos/systems/<hostname>/default.nix`
2. Edit mynixos features in `/home/logger/Code/github/logger/mynixos/modules/`
3. Test with `sudo nixos-rebuild test --flake /etc/nixos#<hostname>`
4. Apply with `sudo nixos-rebuild switch --flake /etc/nixos#<hostname>`
5. Commit changes (single commit per branch)

## Important Notes

- Both repositories must be accessible during builds
- Changes to mynixos require updating the flake lock or rebuilding
- YubiKey serial numbers and fingerprints are personal data
- Hashed password is stored in `/etc/nixos/users/logger/user.nix`
- Home-manager configuration is managed entirely by mynixos
- User "logger" corresponds to "Ido Samuelson"
- when you need you work with an open source project, integrate, etc, best to clone it to ~/Code/github/tmp and learn it for the work purpose
- mynixos is unstable api that means documentations are not important right now. also backwards compatibility isn't important as api is unstable
- do not use sudo