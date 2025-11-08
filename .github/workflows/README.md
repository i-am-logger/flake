# CI/CD Workflow

This directory contains the GitHub Actions workflow for automated testing and validation of the NixOS flake configuration.

## Workflow

### Main CI/CD Pipeline (`ci.yml`)
Comprehensive pipeline that runs on all pushes and pull requests with the following jobs:

1. **Format Check** - Validates Nix code formatting using alejandra or nixpkgs-fmt
2. **Flake Validation** - Validates flake structure, metadata, and outputs
3. **Flake Check** - Runs dry-run and full flake checks
4. **Build Systems** - Builds all system configurations in parallel (yoga, skyspy-dev)
5. **Evaluate Configurations** - Evaluates system configurations to ensure they're valid
6. **Pipeline Summary** - Provides a summary of all check results

### Pipeline Flow

```
Format Check
     ↓
Flake Validation
     ↓
Flake Check (dry-run + full)
     ↓
Build Systems (parallel: yoga, skyspy-dev)
     ↓
Evaluate Configurations
     ↓
Pipeline Summary
```

## Self-Hosted Runners

All jobs are configured to use `runs-on: self-hosted` to leverage your self-hosted GitHub Actions runners. This ensures:

- Access to GPU resources (AMD for yoga, NVIDIA for skyspy-dev)
- Faster builds with local Nix cache
- No GitHub-hosted runner time limits
- Better integration with your hardware setup

## Usage

### Automatic Triggers
The workflow automatically runs on:
- Push to `main` or `master` branches
- Pull requests targeting `main` or `master` branches

### Manual Triggers
The workflow can be manually triggered via:
```bash
# Using GitHub CLI
gh workflow run ci.yml
```

Or through the GitHub web interface: Actions → CI/CD Pipeline → Run workflow

## Requirements

Your self-hosted runners should have:
- Nix installed and configured
- Sufficient disk space for builds
- GPU drivers installed (if testing GPU-enabled systems)
- Access to any private flake inputs

## Local Testing

Before pushing, test locally with the same checks:

```bash
# Check formatting
alejandra --check .
# or
nixpkgs-fmt --check $(find . -name "*.nix" -not -path "*/.*")

# Validate flake
nix flake show --json > /dev/null
nix flake metadata
nix flake show

# Run flake checks
nix flake check --dry-run
nix flake check --all-systems

# Build systems
nix build .#nixosConfigurations.yoga.config.system.build.toplevel -L
nix build .#nixosConfigurations.skyspy-dev.config.system.build.toplevel -L

# Evaluate configurations
nix eval .#nixosConfigurations.yoga.config.system.name
nix eval .#nixosConfigurations.skyspy-dev.config.system.name
```

## Monitoring

### Via GitHub CLI
```bash
# List recent workflow runs
gh run list

# Watch a specific run
gh run watch

# View logs
gh run view <run-id> --log
```

### Via GitHub UI
1. Go to your repository
2. Click "Actions" tab
3. Select "CI/CD Pipeline"
4. View run details and logs

## Troubleshooting

### Workflow Not Starting
- Check if self-hosted runners are online
- Verify runner labels match `runs-on: self-hosted`
- Check runner queue: Settings → Actions → Runners

### Build Failures
- Check logs in GitHub Actions
- Test locally using commands above
- Verify Nix cache is accessible
- Ensure sufficient disk space

### Format Failures
```bash
# Auto-fix formatting issues
alejandra .
# or
find . -name "*.nix" -not -path "*/.*" -exec nixpkgs-fmt {} \;

# Then commit
git add .
git commit -m "Fix formatting"
```

### Flake Check Failures
```bash
# See detailed errors
nix flake check -L

# Show flake metadata
nix flake metadata

# Show all outputs
nix flake show
```
