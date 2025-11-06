# Self-Hosted Runner Debugging Guide

This guide helps troubleshoot issues with GitHub Actions self-hosted runners using Actions Runner Controller (ARC).

## Quick Diagnostics

### 1. Check Runner Status

```bash
# List all runner pods
kubectl get pods -n arc-runners

# Check runner scale sets
kubectl get runners -n arc-runners

# View runner details
kubectl describe runners -n arc-runners
```

### 2. Check Runner Registration

```bash
# View runner labels
kubectl get pods -n arc-runners -o yaml | grep -A5 RUNNER_LABELS

# Expected output should include: self-hosted,build,copilot-agent
# For GPU systems, also: gpu
```

### 3. Check Service Status

```bash
# Check if runner scale set services are running
systemctl status arc-setup.service
systemctl status arc-runner-set-flake.service
systemctl status arc-runner-set-loial.service
systemctl status arc-runner-set-logger.service

# Check if setup completed
ls -la /var/lib/arc-*-done
```

### 4. Verify GitHub Token

```bash
# Check token file exists and is valid
sudo cat /persist/etc/github-runner-token

# Should contain:
# GITHUB_TOKEN=ghp_...
# GITHUB_USERNAME=i-am-logger
```

### 5. Check ARC Controller

```bash
# Check controller pod status
kubectl get pods -n arc-systems

# View controller logs
kubectl logs -n arc-systems deployment/arc-gha-runner-scale-set-controller
```

## Common Issues

### Issue 1: Workflow Waiting for Runner

**Symptom:** Workflow shows "Waiting for a runner to pick up this job"

**Causes:**
1. Runner labels don't match workflow requirements
2. Runner not registered to the correct repository
3. Runner pods not running
4. No available runner capacity (maxRunners reached)

**Solutions:**

```bash
# Check if runners exist for this repo
kubectl get runners -n arc-runners | grep flake

# Check runner pod status
kubectl get pods -n arc-runners -l runner-scale-set=<hostname>-flake

# If no pods, check listener logs
kubectl logs -n arc-runners -l app.kubernetes.io/component=runner-scale-set-listener
```

### Issue 2: Runner Service Failed to Start

**Symptom:** `systemctl status arc-runner-set-flake` shows failed

**Solutions:**

```bash
# View service logs
journalctl -u arc-runner-set-flake.service -n 50

# Common issues:
# - Missing GITHUB_TOKEN in /persist/etc/github-runner-token
# - k3s not ready
# - Network issues pulling Helm charts

# Retry service manually
sudo systemctl restart arc-runner-set-flake.service
```

### Issue 3: GitHub Token Invalid

**Symptom:** Runner can't authenticate with GitHub

**Solutions:**

```bash
# Re-authenticate with GitHub CLI
gh auth login

# Recreate token file
sudo rm /persist/etc/github-runner-token
sudo rm /var/lib/arc-runner-set-*-done
sudo nixos-rebuild switch
```

### Issue 4: Runner Not Scaling

**Symptom:** Workflow queued but no new runners created

**Solutions:**

```bash
# Check listener pod logs
kubectl logs -n arc-runners -l app.kubernetes.io/component=runner-scale-set-listener

# Check scale set configuration
kubectl get runners -n arc-runners -o yaml

# Verify minRunners and maxRunners settings
# Default: minRunners=0, maxRunners=5
```

## Adding a New Repository

To add runners for a new repository (e.g., "flake"):

1. **Update system configuration** - In your system's CICD stack config:
   ```nix
   stacks.cicd = {
     enable = true;
     repositories = [ "loial" "logger" "flake" ];  # Add your repo
     # ...
   };
   ```

2. **Rebuild system:**
   ```bash
   sudo nixos-rebuild switch
   ```

3. **Verify service created:**
   ```bash
   systemctl status arc-runner-set-flake.service
   ```

4. **Check runner registered:**
   ```bash
   kubectl get runners -n arc-runners | grep flake
   ```

## Workflow Configuration

### Default Configuration (in ci.yml)

```yaml
jobs:
  job-name:
    runs-on: self-hosted
```

This matches any runner with the `self-hosted` label.

### With Specific Labels

```yaml
jobs:
  job-name:
    runs-on: [self-hosted, build, gpu]
```

This requires runners with ALL specified labels.

### Current Runner Labels

Based on `Systems/Stacks/cicd/default.nix`:
- `self-hosted` (always)
- `build` (always)
- `copilot-agent` (always)
- `gpu` (if `enableGpu = true`)

## Manual Runner Management

### Force Scale Up

```bash
# Create a dummy workflow run to trigger scaling
# Or manually create runner pods:
kubectl scale runners <hostname>-flake --replicas=1 -n arc-runners
```

### View Runner Logs

```bash
# List runner pods
kubectl get pods -n arc-runners

# View specific runner logs
kubectl logs -n arc-runners <pod-name>

# Follow logs in real-time
kubectl logs -n arc-runners <pod-name> -f
```

### Restart Runner Scale Set

```bash
# Delete and recreate scale set
sudo rm /var/lib/arc-runner-set-flake-done
sudo systemctl restart arc-runner-set-flake.service

# Wait for deployment
sleep 30

# Check status
kubectl get runners -n arc-runners
```

## Verifying End-to-End

Complete verification checklist:

```bash
# 1. k3s is running
sudo systemctl status k3s

# 2. ARC controller is running
kubectl get pods -n arc-systems

# 3. Runner scale set exists
kubectl get runners -n arc-runners

# 4. Listener pod is running
kubectl get pods -n arc-runners -l app.kubernetes.io/component=runner-scale-set-listener

# 5. Runner can be scaled
kubectl scale runners <hostname>-flake --replicas=1 -n arc-runners

# 6. Runner pod starts
kubectl get pods -n arc-runners -w

# 7. Check GitHub UI
# Go to: https://github.com/<username>/<repo>/settings/actions/runners
# Should show: <hostname>-flake runner(s)
```

## Useful Commands

```bash
# View all ARC resources
kubectl get all -n arc-systems
kubectl get all -n arc-runners

# Export runner configuration
kubectl get runners -n arc-runners -o yaml > runners.yaml

# View events
kubectl get events -n arc-runners --sort-by='.lastTimestamp'

# Clean up everything and start fresh
sudo systemctl stop k3s
sudo rm -rf /var/lib/rancher/k3s
sudo rm /var/lib/arc-*-done
sudo systemctl start k3s
sudo nixos-rebuild switch
```

## Getting Help

If issues persist:

1. Check ARC documentation: https://github.com/actions/actions-runner-controller
2. Review GitHub Actions runner logs in the UI
3. Check k3s logs: `journalctl -u k3s -n 100`
4. Verify network connectivity to GitHub
5. Ensure sufficient system resources (CPU, memory, disk)
