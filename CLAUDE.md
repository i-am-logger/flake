# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal system configurations for three hosts — two NixOS, one nix-darwin. Everything is
stated through a custom typed functional DSL called `mynixos`, consumed as the flake input
`github:i-am-logger/mynixos` and exposed as the `my.*` namespace. Local mynixos checkouts
differ per machine (e.g. `/Users/logger/Code/mynixos` on the Mac); iterate against one with
`--override-input mynixos <path>`.

### Where this checkout lives

- **yoga, skyspy-dev**: `/etc/nixos`. `my.storage.impermanence` clones the repo there when
  that directory is empty, and points `~/.flake` at it.
- **aether5d-dev**: `/Users/logger/Code/flake`, declared as `my.system.flakeDir`.

The commands below run from inside the checkout and address it as `.#`.

## Architecture

### Two-Repository Structure

1. **mynixos** (flake input `github:i-am-logger/mynixos`) - Generic typed DSL
   - Provides type constructors and the `my.*` options namespace
   - Defines generic hardware profiles, domain modules and per-user apps under `my/`,
     composed by `platforms/{common,linux,darwin}.nix`
   - Exposes `mynixos.lib.mkSystem` for building NixOS *and* nix-darwin configurations
     (one builder; `platform = "darwin"` selects the evaluator), alongside `lib.hardware`
     (paths to hardware profiles, for out-of-tree use) and `lib.securityKeys`

2. **This repository** - Personal system configurations
   - Hosts in `systems/`, personal data in `users/`
   - Secrets stay outside git and arrive through the `secrets` flake input

### Directory Structure

```
flake/
├── systems/           # Per-host configurations
│   ├── yoga/          # Desktop workstation (Gigabyte X870E)
│   ├── skyspy-dev/    # Laptop (Lenovo Legion 16IRX8H)
│   ├── aether5d-dev/  # MacBook Pro M5 Max (nix-darwin)
│   └── motd.txt       # Login banner, read by both NixOS hosts
├── users/
│   ├── default.nix    # The `my.users` attrset every host imports
│   └── logger/        # Personal user data + YubiKey data + avatar
├── themes/            # Colour palettes, base16-schemes and Wallpapers (data).
│                      # NOTE: nothing in this repo imports them.
├── overlays/          # claude-code.nix, applied by all three hosts
├── installer/         # Custom installer ISO
├── forensic/          # devenv shell for mobile forensics (mvt)
├── scripts/           # Helper scripts
├── docs/              # Documentation
└── flake.nix          # Main flake entry point
```

### Configuration Pattern

System configurations use `mynixos.lib.mkSystem` with this structure:

```nix
mynixos.lib.mkSystem {
  hostname = "...";          # or my.system.hostname; one of the two is required
  platform = "darwin";       # optional; defaults to "linux"

  my = {
    system = { ... };        # Top-level domains — see "Option namespace" below
    hardware = { ... };
    users = import ../../users;   # Personal data, shared by every host
  };

  extraModules = [ ];        # Optional system-specific modules
}
```

`my` may also be a **list of layers**. Each element becomes its own module, so
the module system merges them per option using each option's own type: `listOf`
options concatenate, and two unequal scalars are a hard error rather than a
silent last-wins. That is how a host contributes its own facts without reaching
into the shared user profile:

```nix
my = [
  { system = { ... }; users = import ../../users; }
  { users.logger.github.repositories = [ "loial" "logger" "pds" ]; }   # appends
];
```

### Key Concepts

- **Domains, not features**: options are grouped by domain (`my.network`, `my.hardware`,
  `my.users.<name>.apps`), and platform reach is decided by which of
  `platforms/{common,linux,darwin}.nix` imports the module — not by an `isDarwin` test
- **Hardware profiles**: pre-configured hardware modules from mynixos (motherboards, laptops,
  cooling). On both platforms the profile is what sets `nixpkgs.hostPlatform`, so `mkSystem`
  takes no `system` argument
- **Users are data**: hosts pass no `users` list; accounts are derived from `my.users`,
  which is a plain attrset in `users/` with no `lib` in scope
- **Opinionated defaults**: mynixos supplies them; a host states only what genuinely differs

## Common Commands

### Rebuild scripts (both platforms)

`my.system.enable` installs these on every host. They locate the flake themselves
(`my.system.flakeDir`, then `/etc/nixos`, then `~/.flake`) and dispatch to `nixos-rebuild`
or `darwin-rebuild`:

```bash
build-system      # build only, no activation, no root
test-system       # nixos-rebuild test; on macOS, darwin-rebuild check
rebuild-system    # switch
update-system     # nix flake update in the flake directory
```

`darwin-rebuild` has no `test` action, so `test-system` runs `check` there — it builds and
runs the activation sanity checks but does **not** activate. `update-system` runs a bare
`nix flake update`, which re-fetches every input; see the macOS caveat below.

### NixOS hosts

```bash
# Auto-detect hostname
cd /etc/nixos && sudo nixos-rebuild test --flake .#
cd /etc/nixos && sudo nixos-rebuild switch --flake .#

# Build without activating (check for errors). Needs NO root.
cd /etc/nixos && nixos-rebuild build --flake .#

# Name a host explicitly instead of auto-detecting
sudo nixos-rebuild switch --flake /etc/nixos#yoga
sudo nixos-rebuild switch --flake /etc/nixos#skyspy-dev
```

**Important**: Always run `test` before `switch` to catch issues without committing to bootloader.

Both NixOS hosts are `x86_64-linux` and cannot be built from the Mac. Pure evaluation of
their options and config works there; anything that needs a Linux builder (notably
`config.system.build.toplevel`) does not.

### macOS host

```bash
# Build without activating
nix build .#darwinConfigurations."aether5d-dev".system

# Apply (root required — see the sudo note below)
sudo darwin-rebuild switch --flake .#aether5d-dev

# Roll back
darwin-rebuild --list-generations && sudo darwin-rebuild switch --rollback
```

**Do NOT run `nix flake check`, `nix flake show`, or a bare `nix flake update` on
the Mac.** All three resolve every input, including `secrets`
(`/home/logger/.secrets`), which exists only on the Linux hosts. `nix flake update`
fails even though it never evaluates outputs, because re-locking still fetches.
Use targeted `nix eval` / `nix build`, and name the inputs to update:

```bash
nix flake update mynixos claude-desktop   # works; a bare `nix flake update` does not
```

CI is unaffected: `nix flake check` treats `darwinConfigurations` as a
known-but-unchecked attribute and never evaluates it.

### Validation

```bash
# On a NixOS host
nix flake check
nix flake show

# Pure evaluation — works everywhere, including the Mac
nix eval .#nixosConfigurations.yoga.config.networking.hostName
nix eval .#darwinConfigurations."aether5d-dev".config.networking.hostName
nix eval .#nixosConfigurations.yoga.options.my --apply builtins.attrNames

# Check system closure size (on an activated host)
nix path-info -Sh /run/current-system
```

### Formatting

```bash
# Format all Nix files (run before committing). The formatter is nixpkgs-fmt,
# defined for x86_64-linux and aarch64-darwin.
nix fmt
```

### Updating Dependencies

```bash
# Update mynixos only
nix flake update mynixos

# Inspect the lock
nix flake metadata
```

### Installer ISO

```bash
# x86_64-linux only — packages.x86_64-linux.installer-iso
nix build .#installer-iso

# Same build, with progress reporting and ISO details
./build-installer.sh
```

## System Hosts

### yoga
- **Hardware**: Gigabyte X870E AORUS Elite WiFi7 (AMD desktop), NZXT Kraken Elite 240 RGB
  cooling, Elgato Stream Deck, Keychron K2 HE
- **Storage**: Disko-managed with a dedicated `/persist` partition; impermanence on top
- **Security**: secure boot (lanzaboote), YubiKey via `my.hardware.securityKeys.yubico`,
  audit rules, `nopasswdRebuild`
- **Notable**: greetd + tuigreet login into Hyprland; headscale control server;
  `my.ai.claudeCodeProxy` on and Ollama off; vogix DRAM RGB

### skyspy-dev
- **Hardware**: Lenovo Legion 16IRX8H (Intel laptop, NVIDIA open kernel modules), Elgato
  Stream Deck. Kernel pinned to `linuxPackages_6_12` in `extraModules`
- **Storage**: ext4 root declared in `filesystem.nix`; impermanence with `/persist` as a
  directory on it rather than a dedicated partition
- **Notable**: Windows dual-boot (`my.system.dualBoot.windows`) with a read-only NTFS mount
  at `/home/logger/mnt/windows`; Tailscale client + Tor; `my.ai`, secure boot and
  `my.secrets` all off

### aether5d-dev (macOS, nix-darwin)
- **Hardware**: Apple M5 Max MacBook Pro, `aarch64-darwin`, macOS 27.0
- **Config**: `systems/aether5d-dev/`, one `mynixos.lib.mkSystem { platform = "darwin"; … }`
  call — the same entry point yoga and skyspy-dev use. There is deliberately no
  separate `mkDarwinSystem`. mynixos composes its module set in
  `platforms/{common,linux,darwin}.nix`, and exposes `darwinModules.default`
  alongside `nixosModules.default`.
- **Architecture comes from the hardware profile**, exactly as on NixOS: enabling
  `my.hardware.laptops.apple.macbook-pro-m5-max` is what sets
  `nixpkgs.hostPlatform = "aarch64-darwin"`. `mkSystem` takes no `system` argument
  on either platform. The darwin branch additionally asserts that the resolved
  `hostPlatform` really is darwin, so a host that names `platform = "darwin"`
  without a darwin hardware profile fails with a reason.
- **Notable**: `nix.enable = false` — Nix stays owned by the NixOS `nix-installer`
  (see the comment in `systems/aether5d-dev/default.nix` for why). Touch ID for
  `sudo` including inside zellij, via `my.hardware.biometrics` (Apple vendor
  implementation at `my/hardware/biometrics/apple`). Remote Login is scoped to the
  tailnet by pf through `my.network.sshFirewall`. Homebrew covers only what Nix cannot
  package: Mac App Store apps and the Background Music cask.
- **NOT ACTIVATED.** There is no `/run/current-system`, no `/etc/pam.d/sudo_local`,
  and `darwin-rebuild` is not on PATH, so everything above is build-verified only.
  `systems/aether5d-dev/transition.sh` is the two-phase first-switch procedure
  (`--prepare`, switch, `--cleanup`). On that first switch, apply and verify
  incrementally — a combined first activation makes any failure ambiguous.
- **YubiKey is deliberately not supported here** — see
  `mynixos/docs/yubikey-on-darwin.md`. It would work (macOS ships its own CCID
  driver and needs *less* wiring than NixOS); it is simply redundant with Touch ID
  on this host.

## Option namespace

There is no `my.features`. Options sit under top-level **domains**, and anything
belonging to a person sits under `my.users.<name>`.

System domains (Linux): `ai` `boot` `dev` `environment` `filesystem` `fonts` `forensics`
`graphical` `hardware` `infra` `network` `performance` `presets` `secrets` `security`
`storage` `streaming` `system` `theming` `users` `video`

System domains (darwin): `dev` `fonts` `hardware` `homebrew` `network` `nixGc`
`secrets` `system` `users`

The two lists differ because **an option is declared where its implementation
lives**. `my.homebrew` and `my.nixGc` exist only on darwin; `my.theming`,
`my.storage`, `my.filesystem`, `my.boot` and the rest only on Linux. Setting one on the
wrong platform is `The option `my.homebrew.enable' does not exist`, not a no-op.

Per-user (`my.users.<name>.*`), identical on both platforms: `ai` `apps` `avatar`
`defaults` `description` `dev` `email` `environment` `fullName` `github` `graphical`
`hashedPassword` `hashedPasswordFile` `input` `mounts` `name` `packages`
`persistedDirectories` `secrets` `shell` `terminal` `theming` `yubikeys`

Applications are per-user — `my.users.<name>.apps.<category>.<group>.<app>` —
never a top-level `my.apps`. Each app declares its own option beside its
implementation — in the file that implements it, through `mkApp`'s `option` field,
or in a sibling `options.nix` when the module is not an `mkApp` one (claude-code,
whose module is hand-written; 1password, whose implementation is split into
`default.nix` and `darwin.nix`). Whichever `platforms/*.nix` imports the declaring
file is what decides where the option exists, so an app absent from a platform has
no option there. Every platform-scoped per-user difference sits below the top
level — individual apps, plus `input.accelSpeed`. `tests/user-option-reach.nix`
enumerates both option trees and asserts the exact set of one-sided paths, for the
domains and the per-user tree alike.

A user entry may also carry reserved `linux` and `darwin` keys holding values
that apply on that platform alone. `mkSystem` collapses them before the module
system sees anything, so `my.users.<name>.darwin` never becomes an option path.

## Personal Data Locations

- **Secrets**: the `secrets` flake input, `/home/logger/.secrets/` — not in git, and
  deliberately not threaded into the darwin host
- **Account password**: the sops secret `users/logger/password`, decrypted at activation on
  hosts that set `my.secrets.enable` (yoga). No password hash lives in this repo
- **YubiKey data**: `users/logger/yubikeys.nix` — serials, GPG key IDs, fingerprints, SSH
  keygrips and U2F handles — alongside `users/logger/yubikey{1,2}_pubkey.asc`
- **User avatar**: `users/logger/avatar.png`, consumed by AccountsService on the Linux hosts
- **Impermanence**: the Linux hosts clone `git@github.com:i-am-logger/flake.git` into
  `/etc/nixos` and symlink `~/.flake` to it; the persisted copy is at `/persist/etc/nixos`

## Development Workflow

1. Edit the host in `systems/<hostname>/default.nix`; edit personal data in `users/logger/`
2. Edit generic behaviour under `<mynixos>/my/`, and its platform reach in
   `<mynixos>/platforms/`
3. Iterate against a local mynixos with `--override-input mynixos <path>`
4. Test with `test-system` (or `sudo nixos-rebuild test --flake .#<hostname>`)
5. Apply with `rebuild-system` (or `sudo nixos-rebuild switch --flake .#<hostname>`)
6. Commit changes (single commit per branch)

## Important Notes

- Both repositories must be accessible during builds
- Changes to mynixos need a flake lock update, or `--override-input` for the run
- YubiKey serial numbers and fingerprints are personal data
- `mkSystem` wires home-manager on both platforms, and per-user program configuration comes
  from mynixos's app modules. Hosts set `home.stateVersion` and their own host-specific
  additions (`systems/aether5d-dev/home.nix`)
- User "logger" corresponds to "Ido Samuelson"
- `~/Code` layout: `logger/` holds my own repositories (flat), `cosmic/` holds Cosmic Clarity
  Connection work (its own Claude account, alias `bootstrapper`), and `github/<owner>/<repo>`
  holds clones and forks of other people's repositories
- when you need you work with an open source project, integrate, etc, best to clone it to ~/Code/github/tmp and learn it for the work purpose
- mynixos is unstable api that means documentations are not important right now. also backwards compatibility isn't important as api is unstable
- do not use sudo
  - **Exception, macOS only**: on darwin all system activation runs as root, and
    `darwin-rebuild` refuses to run otherwise (`switch`/`activate`/`rollback`/`check`
    all check `id -u`). There is no `nopasswdRebuild` equivalent on darwin.
    `nix build` and `nix eval` need no privileges — so author and verify without
    sudo, and hand the `sudo darwin-rebuild ...` line to the user to run.
