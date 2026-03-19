# NixOS Configuration

Personal NixOS system configurations built on [mynixos](https://github.com/i-am-logger/mynixos), a typed functional DSL for declarative system management.

## Systems

| Host | Hardware | Role |
|------|----------|------|
| **yoga** | Gigabyte X870E AORUS Elite WiFi7 (AMD) | Primary workstation, always-on server |
| **skyspy-dev** | Lenovo Legion 16IRX8H (Intel/NVIDIA) | Development laptop, dual-boot Windows |

## Architecture

This repo contains **personal data and system-specific configuration**. All modules, hardware profiles, and opinionated defaults live in [mynixos](https://github.com/i-am-logger/mynixos).

```
flake.nix              # Entry point — imports mynixos, defines systems
systems/
  yoga/default.nix     # yoga-specific: headscale, tor, AI, secure boot
  skyspy-dev/default.nix  # skyspy-specific: NVIDIA, dual-boot, tailscale
users/
  logger/              # User data: YubiKey configs, avatar, credentials
overlays/              # Package overrides (claude-code, opencode)
```

Each system is defined with `mynixos.lib.mkSystem` and configures features via the `my.*` option namespace:

```nix
mynixos.lib.mkSystem {
  my = {
    system.hostname = "yoga";
    hardware.motherboards.gigabyte.x870e-aorus-elite-wifi7.enable = true;
    security = { secureBoot.enable = true; yubikey.enable = true; };
    network = {
      headscale.enable = true;
      tailscale = { enable = true; exitNode = true; };
      tor = { enable = true; onionServices.headscale.enable = true; };
    };
    ai = { claudeProxy.enable = true; openclaw.enable = true; };
    # ...
  };
}
```

## Networking

Headscale mesh VPN with Tor-based discovery. No ports exposed to the internet.

- **yoga**: Headscale coordination server + Tor v3 onion service + Tailscale exit node
- **skyspy-dev**: Tailscale client + Tor SOCKS proxy (for .onion bootstrap)
- **SSH**: Enabled automatically via tailscale, pubkey-only (YubiKey), accessible only over the mesh

## Quick Start

```bash
# Build and test
nixos-rebuild build --flake .#yoga
nixos-rebuild test --flake .#yoga

# Apply
nixos-rebuild switch --flake .#yoga

# Update mynixos
nix flake lock --update-input mynixos

# Format
nix fmt
```

## Related

- [mynixos](https://github.com/i-am-logger/mynixos) — The DSL powering these configurations
