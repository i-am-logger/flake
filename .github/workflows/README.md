# CI/CD Workflows

This directory contains GitHub Actions workflows for automated testing and validation of the NixOS flake configuration.

## Workflows

### Main CI/CD Pipeline (`ci.yml`)
Comprehensive pipeline that runs on all pushes and pull requests:
- **Lint and Format**: Checks Nix code formatting using alejandra or nixpkgs-fmt
- **Flake Check**: Validates flake structure with dry-run check
- **Build Systems**: Builds all system configurations (yoga, skyspy-dev)
- **Evaluate Systems**: Evaluates system configurations to ensure they're valid
- **Summary**: Provides a summary of all check results

### Individual Workflows

#### `check.yml` - Flake Check
Validates the flake structure and runs comprehensive checks:
- Dry-run check for quick validation
- Full flake check for all systems

#### `format.yml` - Format Check
Ensures all Nix files follow proper formatting standards using nixpkgs-fmt or alejandra.

#### `build.yml` - Build Systems
Builds each system configuration independently:
- `yoga` - Gigabyte X870E AORUS ELITE WIFI7 (AMD)
- `skyspy-dev` - Lenovo Legion 16IRX8H (Intel/NVIDIA)

#### `test.yml` - System Tests
Validates flake structure and evaluates system configurations:
- Flake metadata validation
- System output listing
- Configuration evaluation

## Self-Hosted Runners

All workflows are configured to use `runs-on: self-hosted` to leverage your self-hosted GitHub Actions runners. This ensures:

- Access to GPU resources (AMD for yoga, NVIDIA for skyspy-dev)
- Faster builds with local Nix cache
- No GitHub-hosted runner time limits
- Better integration with your hardware setup

## Usage

### Automatic Triggers
Workflows automatically run on:
- Push to `main` or `master` branches
- Pull requests targeting `main` or `master` branches

### Manual Triggers
All workflows can be manually triggered via:
```bash
# Using GitHub CLI
gh workflow run ci.yml
gh workflow run check.yml
gh workflow run format.yml
gh workflow run build.yml
gh workflow run test.yml
```

Or through the GitHub web interface: Actions → Select Workflow → Run workflow

## Requirements

Your self-hosted runners should have:
- Nix installed and configured
- Sufficient disk space for builds
- GPU drivers installed (if testing GPU-enabled systems)
- Access to any private flake inputs

## Workflow Order

For the main CI pipeline (`ci.yml`), jobs run in this order:
1. Lint and Format Check
2. Flake Check (dry-run)
3. Build Systems (parallel for each system)
4. Evaluate Systems
5. Summary

Each step must pass before the next begins, except for the build step which runs in parallel for multiple systems.
