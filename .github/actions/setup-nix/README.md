# Setup Nix Action

A reusable composite action that installs Nix with caching for GitHub Actions workflows.

## Purpose

This action provides a centralized, consistent way to set up Nix across all workflows in this repository. It:

- Installs Nix using DeterminateSystems installer
- Configures GitHub Actions caching via magic-nix-cache
- Verifies the installation
- Works on both self-hosted and GitHub-hosted runners

## Usage

```yaml
steps:
  - name: Checkout repository
    uses: actions/checkout@v4
    
  - name: Setup Nix
    uses: ./.github/actions/setup-nix
    
  - name: Use Nix
    run: nix build .#something
```

## Benefits

### Consistency
- **Single source of truth**: Update Nix setup in one place
- **Same configuration**: All jobs use identical Nix setup
- **Version control**: Track Nix installer changes

### Maintainability
- **DRY principle**: Don't repeat Nix installation steps
- **Easy updates**: Change once, applies everywhere
- **Clear intent**: Semantic action name shows purpose

### Flexibility
- **Portable**: Works on self-hosted runners (host-yoga-repo-flake)
- **Compatible**: Also works on GitHub-hosted runners (ubuntu-latest, etc.)
- **Cacheable**: Magic cache speeds up subsequent runs

## What It Does

1. **Installs Nix** using `DeterminateSystems/nix-installer-action@main`
   - Modern, fast installer
   - Flakes enabled by default
   - Better error messages

2. **Sets up caching** using `DeterminateSystems/magic-nix-cache-action@main`
   - Free GitHub Actions cache integration
   - Automatic binary caching
   - No external dependencies

3. **Verifies installation**
   - Displays Nix version
   - Shows Nix store location
   - Confirms setup succeeded

## Switching Between Runners

### Self-Hosted Runners
```yaml
runs-on: host-yoga-repo-flake  # Your self-hosted runner
```

### GitHub-Hosted Runners
```yaml
runs-on: ubuntu-latest  # Standard GitHub runner
```

The `setup-nix` action works identically on both! This gives you flexibility to:
- Use self-hosted for performance (local caching, GPU access)
- Use GitHub-hosted for cost savings or scaling
- Mix both types in the same workflow

## Performance

### First Run (No Cache)
- Nix installation: ~30-60 seconds
- Subsequent Nix operations: Use cached artifacts

### Subsequent Runs (With Cache)
- Nix installation: ~10-20 seconds (cached)
- Nix operations: Much faster with magic-nix-cache

## Advanced Usage

### Custom Nix Configuration
If you need custom Nix settings, modify `.github/actions/setup-nix/action.yml`:

```yaml
- name: Install Nix
  uses: DeterminateSystems/nix-installer-action@main
  with:
    extra-conf: |
      experimental-features = nix-command flakes
      max-jobs = auto
```

### Using in Other Workflows
Any workflow in this repository can use this action:

```yaml
# .github/workflows/my-workflow.yml
jobs:
  my-job:
    runs-on: ubuntu-latest  # Or host-yoga-repo-flake
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-nix
      - run: nix flake check
```

## Comparison

### Before (Repeated steps in each job)
```yaml
jobs:
  job1:
    steps:
      - uses: actions/checkout@v4
      - uses: DeterminateSystems/nix-installer-action@main
      - uses: DeterminateSystems/magic-nix-cache-action@main
      - run: nix build
  
  job2:
    steps:
      - uses: actions/checkout@v4
      - uses: DeterminateSystems/nix-installer-action@main  # Duplicate!
      - uses: DeterminateSystems/magic-nix-cache-action@main  # Duplicate!
      - run: nix flake check
```

### After (Reusable action)
```yaml
jobs:
  job1:
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-nix  # Clean!
      - run: nix build
  
  job2:
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-nix  # Reusable!
      - run: nix flake check
```

## Troubleshooting

### Action not found
**Error**: `Can't find 'action.yml' or 'Dockerfile'`

**Solution**: Make sure to checkout the repository first:
```yaml
- uses: actions/checkout@v4  # Must come before setup-nix
- uses: ./.github/actions/setup-nix
```

### Nix commands fail
Check the action output for the Nix version and store path. If installation failed, the verification step will show the error.

### Cache not working
The magic-nix-cache is automatic. If you suspect caching issues:
1. Check the action logs for cache hits/misses
2. Verify GitHub Actions cache storage isn't full
3. Ensure multiple jobs in same run share the cache

## Migration from Previous Approach

If you have workflows with inline Nix installation:

1. **Replace** this:
```yaml
- name: Install Nix
  uses: DeterminateSystems/nix-installer-action@main
- name: Setup Nix cache
  uses: DeterminateSystems/magic-nix-cache-action@main
```

2. **With** this:
```yaml
- name: Setup Nix
  uses: ./.github/actions/setup-nix
```

## Related Documentation

- [CI/CD Quick Start](../../../CI_CD_QUICKSTART.md) - Overview of CI/CD pipeline
- [DeterminateSystems Nix Installer](https://github.com/DeterminateSystems/nix-installer-action)
- [Magic Nix Cache](https://github.com/DeterminateSystems/magic-nix-cache-action)
