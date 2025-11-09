# flake

[![CI/CD Pipeline](https://github.com/i-am-logger/flake/actions/workflows/ci.yml/badge.svg)](https://github.com/i-am-logger/flake/actions/workflows/ci.yml)
[![Copilot coding agent](https://github.com/i-am-logger/flake/actions/workflows/copilot-swe-agent/copilot/badge.svg)](https://github.com/i-am-logger/flake/actions/workflows/copilot-swe-agent/copilot)

My Personal NixOS ricing configuration - A comprehensive NixOS flake for system configuration and hardware management.

## Overview

This repository contains a modular NixOS configuration using flakes, with a focus on:
- Hardware abstraction and component-based configuration
- Secure boot with lanzaboote
- Secrets management with sops-nix
- Impermanence support
- System theming with Stylix
- Home Manager integration

## Systems

- **yoga** - Lenovo Yoga system configuration
- **skyspy-dev** - Development system configuration

## Project Structure

```
flake/
├── Hardware/              - Hardware modules organized by component
│   ├── motherboards/      - Complete motherboard specifications
│   ├── cpu/               - CPU modules (AMD, Intel)
│   ├── gpu/               - GPU modules (AMD, NVIDIA)
│   ├── audio/             - Audio drivers
│   ├── bluetooth/         - Bluetooth drivers
│   ├── network/           - Network configurations
│   └── boot/              - Boot configurations
├── Systems/               - System-specific configurations
│   └── Stacks/            - System stacks (desktop, security, cicd, mcp-servers)
├── Themes/                - Theme configurations
├── home/                  - Home Manager configurations
├── hosts/                 - Host-specific configurations
├── modules/               - Custom NixOS modules
├── packages/              - Custom packages
├── scripts/               - Utility scripts
└── lib/                   - Library functions
```

## Key Features

- **Modular Hardware Configuration**: Component-based hardware modules for easy system composition
- **Secure Boot**: Integrated lanzaboote for secure boot support
- **Secrets Management**: sops-nix for managing sensitive configurations
- **Impermanence**: Support for ephemeral root filesystem
- **Disk Management**: Automated partitioning with disko
- **Theming**: Unified theming with Stylix
- **GitHub Actions Runners**: Self-hosted runner infrastructure with k3s

## Usage

### Available Outputs

This flake provides two NixOS system configurations:

- **yoga** - Lenovo Yoga laptop configuration with desktop environment
- **skyspy-dev** - Development workstation configuration

### Building a System

To build and switch to a configuration:

```bash
nixos-rebuild switch --flake .#<system-name>
```

Replace `<system-name>` with either `yoga` or `skyspy-dev`.

### Testing Configurations

Before deploying changes, you can validate and test the configurations:

```bash
# Validate flake structure
nix flake check

# Dry-run build (check if configuration is buildable without building)
nix build .#nixosConfigurations.yoga.config.system.build.toplevel --dry-run
nix build .#nixosConfigurations.skyspy-dev.config.system.build.toplevel --dry-run

# Build configuration without switching
nix build .#nixosConfigurations.yoga.config.system.build.toplevel
nix build .#nixosConfigurations.skyspy-dev.config.system.build.toplevel
```

The CI/CD pipeline automatically runs these checks on every push and pull request.

## Hardware Modules

Hardware configurations are organized by component type for maximum reusability:

```nix
imports = [
  ./Hardware/cpu/amd
  ./Hardware/gpu/nvidia
  ./Hardware/audio/realtek
  ./Hardware/bluetooth/realtek
  ./Hardware/network
  ./Hardware/boot
];
```

## License

This work is licensed under the [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](LICENSE).

## Documentation

- [Hardware Documentation](./Hardware/README.md)
- [Hardware Analysis](./HARDWARE_ANALYSIS.md)
- [TODO List](./TODO.md)
