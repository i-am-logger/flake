# flake

[![CI/CD Pipeline](https://github.com/i-am-logger/flake/actions/workflows/ci.yml/badge.svg)](https://github.com/i-am-logger/flake/actions/workflows/ci.yml)
[![Copilot coding agent](https://github.com/i-am-logger/flake/actions/workflows/copilot-swe-agent/copilot/badge.svg)](https://github.com/i-am-logger/flake/actions/workflows/copilot-swe-agent/copilot)
[![Release](https://img.shields.io/github/v/release/i-am-logger/flake)]()

[![Stars](https://img.shields.io/github/stars/i-am-logger/flake)]()
[![Sponsors](https://img.shields.io/github/sponsors/i-am-logger)]()

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

This flake provides:

- **yoga** - Desktop system (AMD Ryzen, Gigabyte X870E)
- **skyspy-dev** - Laptop system (Lenovo Legion 16IRX8H, dual-boot)
- **installer-iso** - Bootable installer ISO for both systems

### Quick Start: Installer ISO

Build a bootable USB installer that can install or update both systems:

```bash
./build-installer.sh
```

See [ISO-QUICKSTART.md](./ISO-QUICKSTART.md) for complete instructions.

### Building a System

To build and switch to a configuration:

```bash
nixos-rebuild switch --flake .#<system-name>
```

Replace `<system-name>` with either `yoga` or `skyspy-dev`.

### Unified Installer Script

For both fresh installs and updates:

```bash
sudo ./install.sh yoga install         # Install or update yoga
sudo ./install.sh skyspy-dev install   # Install or update skyspy-dev
```

See [INSTALLER.md](./INSTALLER.md) for details.

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

## Release Process

This repository uses [release-please](https://github.com/googleapis/release-please) for automated releases based on [Conventional Commits](https://www.conventionalcommits.org/).

### How It Works

1. **Commit with conventional format**: Use prefixes like `feat:`, `fix:`, `docs:`, `chore:` in your commit messages
2. **Automatic PR creation**: Release Please creates/updates a release PR with version bump and changelog
3. **Validation**: Release PR is automatically validated (runner image build/test, system config validation)
4. **Auto-merge**: Once all checks pass, the PR auto-merges
5. **Release artifacts published**:
   - GitHub Runner images: `ghcr.io/i-am-logger/github-runner:latest` and `ghcr.io/i-am-logger/github-runner:<version>`

### Pre-release Artifacts (on every push to main)

- **GitHub Runner**: `ghcr.io/i-am-logger/github-runner:edge` and `ghcr.io/i-am-logger/github-runner:sha-<commit>`

### Release Artifacts (on version release)

- **GitHub Runner**: `ghcr.io/i-am-logger/github-runner:latest` and `ghcr.io/i-am-logger/github-runner:<version>`

### Building Installer ISO

The installer ISO can be built separately when needed:

```bash
# Build installer ISO
nix build .#installer-iso

# Or use the convenience script
./build-installer.sh
```

The installer ISO is not tied to version releases and can be built from any commit.

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
