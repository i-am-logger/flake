# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Repository Overview

This is a personal NixOS flake for "ricing" (customizing) NixOS systems. It manages multiple system configurations with a focus on Hyprland desktop environments, theming with Stylix, and comprehensive dotfiles management through Home Manager.

## Common Commands

### System Management
```bash
# Rebuild and switch to new configuration
sudo nixos-rebuild switch --flake .#

# Update flake inputs and rebuild
nix flake update
sudo nixos-rebuild switch --flake .# --upgrade

# Build without switching (for testing)
sudo nixos-rebuild build --flake .#

# Check flake syntax and dependencies
nix flake check

# Show current system generation info
nix path-info -Sh /run/current-system
```

### Development Scripts
The repository includes custom scripts accessible after system rebuild:
```bash
# Update system flake inputs
update-system

# Rebuild current system
rebuild-system

# Display output management
dp-on   # Enable eDP-1 display
dp-off  # Disable eDP-1 display
```

### Flake Operations
```bash
# Show flake metadata
nix flake metadata

# Show system outputs
nix flake show

# Update specific input
nix flake update <input-name>

# Build specific system configuration
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel
```

## System Configurations

The flake defines multiple NixOS systems:

### `yoga` (Primary Desktop)
- **User**: `logger`
- **Features**: AMD GPU optimization, secure boot (lanzaboote), impermanence, disko partitioning
- **Hardware**: Lenovo Yoga with AMD graphics
- **Location**: `./Systems/yoga/configuration.nix`
- **Build**: `sudo nixos-rebuild switch --flake .#yoga`

### `handlink` (Secondary System)  
- **User**: `snick`
- **Features**: Nvidia GPU, hardware optimizations, Legion laptop support
- **Hardware**: Lenovo Legion 16IRX8H (2023)
- **Location**: `./hosts/handlink.nix`
- **Build**: `sudo nixos-rebuild switch --flake .#handlink`

### `skyspy-dev` (Development System)
- **User**: `logger`
- **Features**: Intel/Nvidia hybrid graphics, dual-boot Windows support, Legion hardware optimizations
- **Hardware**: Lenovo Legion 16IRX8H with Intel CPU and Nvidia discrete GPU
- **Location**: `./Systems/skyspy-dev/configuration.nix`
- **Build**: `sudo nixos-rebuild switch --flake .#skyspy-dev`

## Architecture Overview

### Directory Structure
```
├── flake.nix                 # Main flake definition
├── hosts/                    # Host-specific configurations
│   ├── common/              # Shared host modules
│   └── users/               # User account definitions
├── home/                    # Home Manager configurations
│   ├── common.nix           # Shared user packages/configs
│   ├── cli/                 # CLI tool configurations
│   └── gui/                 # GUI application configs
├── Systems/                 # Hardware-specific system configs
│   ├── yoga/                # Yoga laptop configuration
│   └── mirage/              # Alternative system config
├── Themes/                  # Stylix theming and wallpapers
├── modules/                 # Custom NixOS modules
├── packages/                # Custom package definitions
├── scripts/                 # Build and utility scripts
└── cachix/                  # Binary cache configurations
```

### Key Components

**Theming System (Stylix)**
- Base16 color schemes in `Themes/`
- Custom theme: `mission_hacker_white.yaml`
- System-wide theming for all applications
- Font configuration: FiraCode Nerd Font primary, Noto fallback

**Home Manager Integration**
- User-specific configurations in `home/`
- CLI tools: helix, starship, btop, zellij, cava
- GUI apps: hyprland, ghostty, wezterm, obs-studio
- Modular configuration system

**Security Features**
- Secure Boot with lanzaboote (yoga system)
- YubiKey GPG integration
- 1Password integration
- Audit logging configuration
- SOPS-nix for secrets management

**Development Environment**
- Direnv integration for per-project environments
- Nix development tools
- Code editors: VS Code, Cursor support
- Terminal multiplexer: Zellij

### Hardware Optimizations

**AMD Graphics (yoga)**
- AMDGPU kernel parameters for HDR and DisplayPort MST
- Hardware acceleration packages (amdvlk, libva-utils)
- 32-bit support for Steam/gaming

**System Performance**
- BBR TCP congestion control
- Memory and I/O optimizations via kernel.sysctl
- zramSwap with 15% of RAM
- System closure caching service for faster boots

### Partition Management
- **Disko**: Declarative disk partitioning
- **Impermanence**: Stateless system with persistent data
- Configurations in `Systems/*/disko.nix`

## Important Files to Modify

- **Adding new systems**: Edit `flake.nix` outputs.nixosConfigurations
- **User packages**: Modify `home/common.nix` or user-specific files
- **System packages**: Edit host configurations in `hosts/`
- **Themes**: Modify `Themes/stylix.nix` and color schemes
- **Secrets**: Update `secrets` flake input path

## Development Workflow

1. **Make changes** to configurations
2. **Test build**: `sudo nixos-rebuild build --flake .#`
3. **Apply changes**: `sudo nixos-rebuild switch --flake .#`
4. **Update dependencies**: `nix flake update` when needed
5. **Commit changes** to maintain configuration history

The system emphasizes declarative configuration, reproducibility, and aesthetic consistency across all applications through the Stylix theming system.
