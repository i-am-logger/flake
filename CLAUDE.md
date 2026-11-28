# CLAUDE.md (flake)

**Read first: the Nix rules**, `<mynixos>/docs/nix-rules.md` (local: `~/Code/logger/mynixos/docs/`;
until it lands there, the draft `~/Code/logger/.build/myoslabs-architect/nix-rules.md`). They bind
here. This file holds only flake's own deltas; a rule for every Nix repo goes there, not here.

## What this repo is
Personal configuration of four hosts in the mynixos DSL (`my.*`, `mynixos.lib.mkSystem`):
- **ads-dev1**: Threadripper workstation. Checkout `~/Code/logger/flake`; `/etc/nixos` links to it.
- **yoga**: X870E desktop. **skyspy-dev**: Legion laptop. Both check out to `/etc/nixos`.
- **aether5d-dev**: M5 Max Mac (nix-darwin), `/Users/logger/Code/flake`. Not yet activated.

Hosts are `systems/<host>/`, personal data `users/` (`users/default.nix` is `my.users`), flake's own
packages `pkgs/`, its checks the `checks` output of `flake.nix`.

## Commands
- Build, no root: `build-system`, or
  `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`. On ads-dev1, prefix
  `taskset -c 16-55,80-119` (`~/Code/logger/CPU-SLICES.md`).
- Gate before landing: `scripts/gate.sh <label>`: every check, the 4-host eval, the ads-dev1 build
  and the closure diff, in one log whose last line is the verdict.
- `test-system` before `rebuild-system`. A switch builds from `flake.lock` only (`--local` is for
  test/build). Switches are release's, in a timing window.
- Iterate against a local mynixos: `--override-input mynixos ~/Code/logger/mynixos`.
- `nix fmt` (nixpkgs-fmt) before committing. Installer ISO: `nix build .#installer-iso`.

## Deltas
- The three NixOS hosts are x86_64-linux; from the Mac only pure evaluation works. **On the Mac never
  run `nix flake check`, `nix flake show` or a bare `nix flake update`**: they fetch every input,
  including `secrets`, which exists only on Linux. Name the inputs (`nix flake update mynixos`).
- **No sudo.** The one exception is darwin activation, which needs root: verify with `nix build`/
  `nix eval`, then hand the owner `sudo darwin-rebuild switch --flake .#aether5d-dev`. The first
  switch follows `systems/aether5d-dev/transition.sh`.
- **Rebuilds** go through `rebuild-system`, in release's timing window. Never probe `hyprctl` or the
  compositor on the owner's live desktop; use a VM or a nested test.
- **Third-party code** is cloned to `~/Code/github/{owner}/{repo}` and built in its own devenv.
- Secrets: sops-nix decrypts `/persist/etc/sops/secrets.yaml` with `/persist/etc/sops-age-keys.txt`.
  YubiKey data (`users/logger/yubikeys.nix`) and serials are personal data.
- ads-dev1 is a staged bring-up (no secure boot, no `my.secrets` yet). Its open gates are listed at
  the bottom of `systems/ads-dev1/default.nix`.
- vogix comes from flake's own `vogix` input, which mynixos's follows (owner, 2026-11-28: no mynixos
  edits for vogix v1). Move the pin there.
- Names live here, never in mynixos: accounts, pools, hostnames, hardware facts.
- `~/Code`: `logger/` holds own repos (flat), `cosmic/` Cosmic Clarity work,
  `github/<owner>/<repo>` others' clones. User `logger` is Ido Samuelson.
- This file is exactly its budget in `budgets.toml` (`[docs] claude_md_bytes`, at most 4096;
  `checks.instructions-size`, decision 0180). Shrink it and lower the budget in the same commit; a
  raise is a commit of its own that says why.
