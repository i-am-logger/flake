# GitHub Actions Runners SubSystem

Self-contained subsystem for deploying GitHub Actions Runner Controller (ARC) on k3s.

## Components

- **k3s cluster**: Lightweight Kubernetes distribution
- **Actions Runner Controller**: Autoscaling runner infrastructure
- **Multi-repository support**: Configurable list of repositories
- **Token management**: Automated via gh CLI
- **Monitoring tools**: arc-status, arc-tui, arc-watch, arc-logs

## Configuration

```nix
{
  imports = [ ./Systems/SubSystems/github-actions-runners ];
}
```

## Features

- Hostname-based runner naming
- Persistent storage with impermanence support
- Declarative configuration
- Minimal TUI with real-time updates

## Scripts

- `arc-status-script.sh`: Status reporting
- `arc-tui-script.sh`: Interactive monitoring TUI
