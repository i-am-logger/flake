# NixOS Configuration Architecture

## Hierarchy

```
/etc/nixos/
├── Systems/
│   ├── SubSystems/              # Higher-order functional modules
│   │   ├── services/            # Reusable service building blocks
│   │   │   ├── k3s.nix
│   │   │   ├── postgresql.nix
│   │   │   ├── redis.nix
│   │   │   ├── docker.nix
│   │   │   ├── nginx.nix
│   │   │   └── default.nix
│   │   ├── applications/        # Application-level modules
│   │   │   ├── grafana.nix
│   │   │   ├── prometheus.nix
│   │   │   └── default.nix
│   │   ├── github-actions-runners/  # Composite subsystem
│   │   ├── mcp-servers/
│   │   ├── security/
│   │   ├── development-environment/
│   │   └── default.nix
│   ├── common/                  # Shared configs across systems
│   ├── yoga/                    # System-specific configs
│   ├── beehive/
│   └── skyspy-dev/
├── hosts/                       # Host-level configurations
└── modules/                     # Custom NixOS modules
```

## Layers

### 1. Services (`SubSystems/services/`)
**Purpose**: Low-level, single-purpose service configurations

**Characteristics**:
- Focused on ONE service/daemon
- Reusable across multiple subsystems
- Minimal dependencies
- Options under `services.subsystems.<name>`

**Examples**:
- k3s - Kubernetes
- postgresql - Database
- redis - Caching
- nginx - Web server
- docker - Container runtime

**Pattern**:
```nix
{ config, lib, pkgs, ... }:
{
  options.services.subsystems.<service> = {
    enable = mkEnableOption "<service>";
    # Service-specific options
  };
  
  config = mkIf cfg.enable {
    # Service configuration
  };
}
```

### 2. Applications (`SubSystems/applications/`)
**Purpose**: Application-level configurations that may use services

**Characteristics**:
- User-facing applications
- May depend on services (e.g., Grafana needs PostgreSQL)
- Options under `applications.subsystems.<name>`

**Examples**:
- grafana
- prometheus
- vault
- authentik

**Pattern**:
```nix
{ config, lib, pkgs, ... }:
{
  options.applications.subsystems.<app> = {
    enable = mkEnableOption "<app>";
    # App-specific options
  };
  
  config = mkIf cfg.enable {
    # May enable services
    services.subsystems.postgresql.enable = true;
    # App configuration
  };
}
```

### 3. Subsystems (`SubSystems/`)
**Purpose**: Higher-order functional modules combining services + applications + config

**Characteristics**:
- Domain/feature-focused (security, development, CI/CD)
- Compose multiple services and applications
- Self-contained with all dependencies
- Options under `subsystems.<name>`

**Examples**:
- github-actions-runners (uses k3s service)
- security (secure-boot + yubikey)
- development-environment (warp + vscode + browser)
- monitoring-stack (prometheus + grafana + alertmanager)

**Pattern**:
```nix
{ config, lib, pkgs, ... }:
{
  options.subsystems.<name> = {
    enable = mkEnableOption "<name>";
    # Subsystem-specific options
  };
  
  config = mkIf cfg.enable {
    # Enable required services
    services.subsystems.k3s.enable = true;
    
    # Enable required applications
    applications.subsystems.grafana.enable = true;
    
    # Custom configuration
  };
}
```

### 4. Systems (`Systems/<hostname>/`)
**Purpose**: System-specific configurations

**Characteristics**:
- Hardware configuration
- Enable subsystems needed
- System-specific overrides
- Minimal custom config (delegate to subsystems)

**Pattern**:
```nix
{
  imports = [ ../SubSystems ];
  
  # Enable what this system needs
  subsystems.security.enable = true;
  subsystems.development-environment.enable = true;
  subsystems.github-actions-runners.enable = true;
  
  # System-specific settings
  networking.hostName = "yoga";
}
```

### 5. Common (`Systems/common/`)
**Purpose**: Truly universal configs shared by ALL systems

**Use sparingly** - prefer subsystems for reusability

## Decision Tree

When adding new functionality, ask:

```
Is it a single service/daemon?
├─ YES → Add to services/
└─ NO → Is it a user-facing application?
    ├─ YES → Add to applications/
    └─ NO → Is it a complete functional bundle?
        ├─ YES → Add as subsystem/
        └─ NO → Is it system-specific?
            ├─ YES → Add to Systems/<hostname>/
            └─ NO → Add to common/ (rare)
```

## Benefits

1. **Composability**: Mix and match services, apps, subsystems
2. **Reusability**: Services used by multiple subsystems
3. **Maintainability**: Change service config once, affects all users
4. **Testability**: Each layer testable independently
5. **Discoverability**: Clear hierarchy, easy to find things
6. **Scalability**: Add new systems/subsystems without touching existing

## Examples

### Example 1: Monitoring Stack Subsystem
```nix
# SubSystems/monitoring-stack/default.nix
{
  subsystems.monitoring-stack.enable = true;
  # Internally uses:
  # - services.subsystems.postgresql
  # - applications.subsystems.grafana
  # - applications.subsystems.prometheus
}
```

### Example 2: Web Hosting Subsystem
```nix
# SubSystems/web-hosting/default.nix
{
  subsystems.web-hosting.enable = true;
  # Internally uses:
  # - services.subsystems.nginx
  # - services.subsystems.postgresql
  # - services.subsystems.redis
  # - applications.subsystems.authentik
}
```

### Example 3: Development System
```nix
# Systems/dev-laptop/configuration.nix
{
  imports = [ ../SubSystems ];
  
  subsystems.development-environment.enable = true;
  subsystems.security.enable = true;
  # That's it! All dependencies resolved automatically
}
```

## Migration Path

1. ✅ Extract k3s service
2. Rename `SubSystems/` → `Stacks/`
3. Create `Infra/services/` and `Infra/apps/`
4. Move k3s to `Infra/services/`
5. Update option paths: `subsystems.*` → `stacks.*`
6. Update Stacks to use `infra.*` options
7. Update machine configs to import from `Stacks/`

## Future Enhancements

- **Profiles**: Preset bundles (workstation, server, minimal)
- **Environments**: Dev, staging, production configurations
- **Secrets**: Integrate with sops-nix at appropriate layers
- **Testing**: CI testing for each layer independently
