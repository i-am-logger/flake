# Runner Quick Reference

Quick commands for managing self-hosted GitHub Actions runners.

## Status Checks

```bash
# Overall status
kubectl get all -n arc-runners
systemctl status arc-runner-set-flake

# Runner details
kubectl get runners -n arc-runners
kubectl describe runners <hostname>-flake -n arc-runners

# Pod status
kubectl get pods -n arc-runners
kubectl logs -n arc-runners <pod-name>
```

## Common Fixes

### Runner Not Picking Up Jobs

```bash
# 1. Check runner exists
kubectl get runners -n arc-runners | grep flake

# 2. Check listener pod
kubectl logs -n arc-runners -l app.kubernetes.io/component=runner-scale-set-listener

# 3. Verify labels
kubectl get pods -n arc-runners -o yaml | grep -A5 RUNNER_LABELS

# 4. Check GitHub UI
# Visit: https://github.com/i-am-logger/flake/settings/actions/runners
```

### Service Failed

```bash
# View logs
journalctl -u arc-runner-set-flake.service -n 50

# Restart service
sudo systemctl restart arc-runner-set-flake.service

# Check completion marker
ls -la /var/lib/arc-runner-set-flake-done
```

### Fresh Start

```bash
# Clean and rebuild
sudo rm /var/lib/arc-runner-set-flake-done
sudo systemctl restart arc-runner-set-flake.service

# Or full reset (careful!)
sudo systemctl stop k3s
sudo rm -rf /var/lib/rancher/k3s/*
sudo rm /var/lib/arc-*-done
sudo systemctl start k3s
sudo nixos-rebuild switch
```

## GitHub Token

```bash
# Check token
sudo cat /persist/etc/github-runner-token

# Regenerate
gh auth login
sudo rm /persist/etc/github-runner-token
sudo nixos-rebuild switch
```

## Scaling

```bash
# Manual scale
kubectl scale runners <hostname>-flake --replicas=2 -n arc-runners

# Check current scale
kubectl get runners -n arc-runners -o wide
```

## Monitoring

```bash
# Watch pods
kubectl get pods -n arc-runners -w

# Tail logs
kubectl logs -n arc-runners <pod-name> -f

# Events
kubectl get events -n arc-runners --sort-by='.lastTimestamp'
```

## Documentation

- Full guide: `RUNNER_DEBUGGING.md`
- CICD config: `Systems/Stacks/cicd/default.nix`
- Workflow: `.github/workflows/ci.yml`
