# CI/CD Quick Start Guide

## Overview

Your flake now has a complete CI/CD pipeline using GitHub Actions with self-hosted runners. This ensures fast builds with GPU access and local Nix cache.

## Workflows Available

### 🚀 Main CI Pipeline
**Workflow:** `.github/workflows/ci.yml`

**What it does:**
1. Checks code formatting (alejandra/nixpkgs-fmt)
2. Validates flake structure (dry-run check)
3. Builds all system configurations in parallel
4. Evaluates system configurations
5. Provides a summary of results

**When it runs:**
- Every push to main/master
- Every pull request
- Manual trigger via GitHub UI

### 📋 Individual Workflows

#### Flake Check
```bash
gh workflow run check.yml
```
Runs comprehensive flake validation and checks.

#### Format Check
```bash
gh workflow run format.yml
```
Validates Nix code formatting standards.

#### Build Systems
```bash
gh workflow run build.yml
```
Builds yoga and skyspy-dev configurations.

#### System Tests
```bash
gh workflow run test.yml
```
Evaluates and tests system configurations.

## Self-Hosted Runner Setup

Your workflows expect self-hosted runners with:
- ✅ Nix installed
- ✅ GPU drivers (AMD for yoga, NVIDIA for skyspy-dev)
- ✅ Sufficient disk space
- ✅ Access to flake inputs

### Verifying Runners

Check your self-hosted runners:
```bash
gh api repos/:owner/:repo/actions/runners
```

Or via GitHub UI:
Settings → Actions → Runners

## Local Testing

Before pushing, test locally:

### 1. Format Code
```bash
# Using alejandra (recommended)
alejandra .

# Or using nixpkgs-fmt
find . -name "*.nix" -not -path "*/.*" -exec nixpkgs-fmt {} \;
```

### 2. Check Flake
```bash
# Quick dry-run check
nix flake check --dry-run

# Full check
nix flake check
```

### 3. Build Systems
```bash
# Build yoga
nix build .#nixosConfigurations.yoga.config.system.build.toplevel -L

# Build skyspy-dev
nix build .#nixosConfigurations.skyspy-dev.config.system.build.toplevel -L
```

### 4. Evaluate Systems
```bash
# Check system names
nix eval .#nixosConfigurations.yoga.config.system.name
nix eval .#nixosConfigurations.skyspy-dev.config.system.name

# Check hostnames
nix eval .#nixosConfigurations.yoga.config.networking.hostName
nix eval .#nixosConfigurations.skyspy-dev.config.networking.hostName
```

## Monitoring Workflows

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
3. Select a workflow
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

# Or
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

## Best Practices

### Before Pushing
1. ✅ Format your code
2. ✅ Run `nix flake check --dry-run`
3. ✅ Build locally if making system changes
4. ✅ Review changes with `git diff`

### When Adding New Systems
1. Add hardware module in `Hardware/motherboards/`
2. Create system definition in `Systems/`
3. Update `flake.nix` nixosConfigurations
4. Add to build matrix in `.github/workflows/build.yml`

### Managing Workflow Failures
- Don't ignore CI failures
- Fix issues before merging PRs
- Use workflow logs to debug
- Test locally to reproduce issues

## Useful Commands

```bash
# Trigger CI workflow manually
gh workflow run ci.yml

# List all workflows
gh workflow list

# View workflow file
gh workflow view ci.yml

# Cancel a running workflow
gh run cancel <run-id>

# Re-run a failed workflow
gh run rerun <run-id>

# Download workflow artifacts (if any)
gh run download <run-id>
```

## Getting Help

### Documentation
- Workflow docs: `.github/workflows/README.md`
- Refactoring guide: `REFACTORING_TODO.md`
- Summary: `REFACTORING_SUMMARY.md`
- Hardware analysis: `HARDWARE_ANALYSIS.md`

### Common Issues
- **"Nix command not found"**: Install Nix on runner
- **"Permission denied"**: Check runner permissions
- **"Disk full"**: Clean up Nix store: `nix-collect-garbage -d`
- **"GPU not found"**: Verify GPU drivers on runner

### Resources
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Self-hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Nix Manual](https://nixos.org/manual/nix/stable/)
