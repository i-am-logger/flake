# NixOS + nix-darwin Configuration

Personal system configurations built on [mynixos](https://github.com/i-am-logger/mynixos), a typed functional DSL for declarative system management.

## Systems

| Host | Hardware | Role |
|------|----------|------|
| **yoga** | Gigabyte X870E AORUS Elite WiFi7 (AMD) | Primary workstation, Headscale coordination server |
| **skyspy-dev** | Lenovo Legion 16IRX8H (Intel/NVIDIA) | Development laptop, dual-boot Windows |
| **aether5d-dev** | Apple M5 Max MacBook Pro (`aarch64-darwin`) | macOS laptop, via nix-darwin |

## Architecture

This repo contains **personal data and system-specific configuration**. The reusable parts — the `my.*` modules, the hardware profiles, the opinionated defaults — live in [mynixos](https://github.com/i-am-logger/mynixos), which composes its module set in `platforms/{common,linux,darwin}.nix`. Which of those files imports a module is what decides where its options exist, so a Linux-only option set on macOS is an evaluation error rather than a silent no-op. What stays here is what belongs to one machine: the macOS system defaults, the claude-code overlay, the installer image.

```
flake.nix              # Entry point — inputs, nixosConfigurations, darwinConfigurations
systems/
  yoga/                # AMD desktop: disko + /persist, secure boot, Headscale
  skyspy-dev/          # Intel/NVIDIA laptop: dual-boot Windows, Tailscale, Tor
  aether5d-dev/        # Apple Silicon: nix-darwin, Touch ID, macOS defaults, Homebrew
users/
  logger/              # User data: YubiKey public keys, avatar, per-platform tiers
overlays/
  claude-code.nix      # claude-code pinned to its linux-x64 native binary release
installer/             # Installer ISO — packages.x86_64-linux.installer-iso
docs/                  # Secure boot setup, reliability playbooks
```

Every host, Linux and macOS alike, is one `mynixos.lib.mkSystem` call. `platform` defaults to `"linux"`, and there is no `system` argument on either platform — the hardware profile is what sets `nixpkgs.hostPlatform`.

```nix
mynixos.lib.mkSystem {
  my = [
    {
      system = {
        enable = true;
        hostname = "yoga";
      };

      hardware = {
        motherboards.gigabyte.x870e-aorus-elite-wifi7.enable = true;
        securityKeys.yubico.enable = true;
      };

      # `enable` gates the whole stack — every block inside my/security is
      # `mkIf (cfg.enable && …)`, so secureBoot alone is inert.
      security = { enable = true; secureBoot.enable = true; };
      network.headscale = { enable = true; port = 8090; };
      ai = {
        enable = true;
        claudeCodeProxy = { enable = true; model = "opus"; };
      };

      # Personal data, shared verbatim by every host.
      users = import ../../users;
    }

    # `my` accepts a list of layers, and each layer becomes its own module, so
    # the module system merges them per option using that option's own type:
    # `repositories` is a listOf, so this concatenates rather than replaces.
    { users.logger.github.repositories = [ "loial" "logger" "pds" ]; }
  ];

  extraModules = [ ];
}
```

The macOS host asks for the darwin evaluator, and names itself with the top-level `hostname` parameter — which either platform accepts in place of `my.system.hostname`:

```nix
mynixos.lib.mkSystem {
  platform = "darwin";
  hostname = "aether5d-dev";

  my = {
    hardware.laptops.apple.macbook-pro-m5-max.enable = true;
    # ...
  };
}
```

A user entry under `users/` may carry reserved `linux` and `darwin` keys holding values that apply on that platform alone — the sops password hash and the greeter avatar are Linux, the menu-bar sleep toggle is macOS. `mkSystem` collapses them for the host's platform before any module evaluates, so `my.users.<name>.darwin` is never an option path.

## Networking

- **yoga** runs Headscale, the self-hosted coordination server, bound to `127.0.0.1:8090`, with ACL groups for the `logger` and `logger-mobile` users.
- **skyspy-dev** runs a Tailscale client plus a Tor SOCKS proxy for reaching `.onion` addresses.
- **aether5d-dev** joins the tailnet through the Mac App Store Tailscale build, which uses Apple's NetworkExtension. Inbound traffic is default-deny under pf, and the allows key on the **Tailscale address ranges** (`100.64.0.0/10`, `fd7a:115c:a1e0::/48`) rather than on an interface, because the tunnel's `utun*` device has no stable name. That is what scopes Remote Login to the tailnet: `sshd_config`'s `ListenAddress` is inert on macOS, where launchd owns the socket. The macOS application firewall is a complementary layer, on and in stealth mode — it filters per application, so it cannot express this itself.
- **SSH on the Linux hosts** is pubkey-only: `PasswordAuthentication` off, `AuthenticationMethods publickey`, root login refused. mynixos enables `sshd` wherever Tailscale is and fills `authorized_keys` from each user's YubiKey SSH keys — so yoga, which hosts the control server without joining the tailnet itself, runs no `sshd` at all. Neither Linux host is reachable on a TCP port from the wider network: yoga's firewall admits none, and skyspy-dev admits only port 22, on `tailscale0` alone.

## Quick Start

```bash
# Linux — build, test, then apply. `build` needs no privileges; `test` and
# `switch` activate, so they need root like any other activation.
nixos-rebuild build --flake .#yoga
sudo nixos-rebuild test --flake .#yoga
sudo nixos-rebuild switch --flake .#yoga

# macOS (nix-darwin) — activation is root-only
nix build .#darwinConfigurations."aether5d-dev".system
sudo darwin-rebuild switch --flake .#aether5d-dev

# Iterate against a local mynixos checkout
nixos-rebuild build --flake .#yoga --override-input mynixos ~/Code/mynixos

# Update mynixos
nix flake lock --update-input mynixos

# Format
nix fmt
```

On the Mac, reach for targeted `nix eval` and `nix build` instead of `nix flake check` or `nix flake show`: those evaluate every output and so force the `secrets` input, a path that exists only on the Linux hosts.

## Related

- [mynixos](https://github.com/i-am-logger/mynixos) — The DSL powering these configurations
