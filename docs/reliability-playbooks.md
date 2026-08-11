# Session reliability playbooks (yoga)

> Principle: **never reboot to fix something — recover in-session.** Each playbook is symptom → diagnose → **recover (in-session)** → the declarative fix that keeps it from recurring. These are the seed for `vogix recover`. See `project_vogix_session_reliability` (memory) for the research grounding.
>
> Shell note: in a degraded session set `export XDG_RUNTIME_DIR=/run/user/$(id -u) DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"` first. Process checks: use `pgrep -f` for `vogix input`/`vogix daemon` (same comm), and remember NixOS wrappers report comm `.NAME-wrapped` (so `pgrep -x waybar`/`-x Hyprland` give false negatives — use `-f` or the systemd unit state).

## P1 — vogix keybindings dead after a Hyprland restart/GPU-reset (stale socket)
- **Symptom:** keys do nothing; `journalctl --user -u vogix-input` shows `dispatch '…' failed: Connection refused (os error 111); will re-discover compositor`.
- **Cause:** the crashed compositor's `.socket.sock` lingers on disk, and the stale `$HYPRLAND_INSTANCE_SIGNATURE` in the engine's environment still names the dead instance.
- **Self-heal:** `Hypr::discover()` (vogix `src/input/hypr.rs`) connection-tests each candidate and skips the dead ones — `$HYPRLAND_INSTANCE_SIGNATURE` first, then every other instance socket under `$XDG_RUNTIME_DIR/hypr` and `/tmp/hypr`, newest-modified first. A failed dispatch drops the handle and the next action re-discovers, so the engine re-attaches to the live compositor with no service restart. One warning followed by working keys is this working.
- **Recover:** if keys stay dead, `systemctl --user restart vogix-input`. The unit deliberately caps its own restart loop (`StartLimitBurst=3`, `StartLimitIntervalSec=30`) so a broken engine can never hold the keyboard hostage — three failures inside 30 s leave it `failed`, and it needs `systemctl --user reset-failed vogix-input` before it will start again.

## P2 — the whole user-service cohort is dead (user@UID.service OOM-killed)
- **Symptom:** no keybindings/bar/audio/idle; `systemctl --user` → `Failed to connect to user scope bus: Connection refused`; `pgrep -u $(id -u) -x systemd` empty.
- **Diagnose:** `systemctl status user@$(id -u).service` → `failed (Result: signal)` / `code=killed`; `journalctl -b -k | grep -iE 'oom|Killed process'` names the runaway (e.g. `pr4xis_domains-` ~4.4 GB × N).
- **Recover (in-session, no re-login):**
  1. **Stop the runaway first** (or it re-OOMs): identify + kill it (e.g. `pkill -f 'nextest run -p pr4xis-domains'`).
  2. Restart the manager: `systemctl restart user@$(id -u).service` *(needs polkit/sudo — a kernel OOM kill is not covered by `Restart=` (systemd#36529), so the manager never comes back on its own).*
  3. **Re-import the session env** (the revived manager comes up empty): `systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP DISPLAY` then `dbus-update-activation-environment --systemd …` (values from the live Hyprland).
  4. Start the cohort by unit (do **not** `systemctl --user start graphical-session.target` — it is `RefuseManualStart=yes` by design): `systemctl --user start vogix-input vogix-daemon waybar pipewire pipewire-pulse wireplumber`.
  5. Clear any orphaned holders — see **P3**.
- **Recover without privilege:** `scripts/recover-session.sh` skips the manager entirely and relaunches the cohort as detached processes inside the live Hyprland session, deriving the instance signature from the newest socket directory rather than trusting the inherited env. It is idempotent (only starts what is actually dead) and logs to `~/.local/state/vogix/recover-session.log`. It does not bring back `dbus-broker`, so tray icons and some IPC stay degraded until the manager is running again.
- **Why this is rare:** the manager carries `OOMScoreAdjust=-900` — see the PREVENT pillar below.

## P3 — audio dead / a service stuck `start-limit-hit` (orphaned process holds a lock)
- **Symptom:** `wpctl status` shows zero sinks; `journalctl --user -u pipewire` → `unable to lock lockfile '/run/user/UID/pipewire-0.lock': Resource temporarily unavailable` → `start-limit-hit`.
- **Cause:** a pre-crash process reparented to init survives in the login `session-N.scope` (outliving `user@`) and holds the runtime socket/lock, blocking the systemd unit.
- **Recover (in-session):**
  1. Find + kill the orphan: `ps -e -o pid,ppid,args | grep '[p]ipewire'` → `kill <PID>` (PPID 1, in `session-N.scope`).
  2. Clear stale runtime files if they linger: `rm -f /run/user/$(id -u)/pipewire-0{,.lock,-manager,-manager.lock}`.
  3. `systemctl --user reset-failed pipewire{,.socket} pipewire-pulse{,.socket} wireplumber` *(required — a plain `restart` won't move past start-limit-hit)*.
  4. `systemctl --user restart pipewire.socket pipewire pipewire-pulse.socket pipewire-pulse wireplumber` → `wpctl status` shows sinks.
- **Note:** device ACLs (`/dev/snd`) are logind-owned, keyed to the **active session/seat** (not `user@`) — they survive a manager restart. Seat activation is NOT the blocker; the orphan-lock is.
- **Prevention:** the PREVENT pillar keeps the cohort from dying in the first place; `vogix recover` will fold orphan-detection + `reset-failed` into one command.

## P4 — Hyprland (and the session) dies on a GPU reset
- **Symptom:** full Hyprland crash/restart; `journalctl -b -k` → `amdgpu … ring gfx timeout → GPU reset succeeded`. Hyprland RASSERT-aborts on any GPU reset (#9746, unimplemented recovery).
- **Cause:** `GCVM_L2_PROTECTION_FAULT` (a shader hits unmapped memory) → `ring gfx timeout` → full GPU reset. The iGPU driver module attributes the fault to the RDNA2 graphics-engine power-off/-on (GFXOFF) transition; the GPU client submitting the work on yoga is the Brave/Chromium GPU process.
- **Diagnose:** `my.forensics.gpu` collects the evidence on its own — a udev rule starts `amdgpu-devcoredump-capture@<devcdN>` the instant the kernel creates a devcoredump, copying the dump (the faulting shader / IB disassembly) into `/var/log/forensics/gpu` ahead of its ~5-minute auto-expiry and snapshotting each user's `~/.cache/brave-gpu-debug.log` beside it, both group-readable by wheel so no sudo is needed to read them (`mynixos/my/hardware/gpu/amd/default.nix`). That browser log exists because the mynixos Brave wrapper runs with `--enable-gpu-driver-debug-logging` and `--log-file=~/.cache/brave-gpu-debug.log`.
- **Prevent (declared):** GFXOFF is disabled on yoga. The board's iGPU driver sets `amdgpu.ppfeaturemask=0xfff73fff` — this GPU's default PowerPlay mask `0xfff7bfff` with only the GFXOFF bit (`0x8000`) cleared, every other feature left at its default — in `mynixos/my/hardware/motherboards/gigabyte/x870e-aorus-elite-wifi7/drivers/amd-integrated-gpu.nix`. Enabling the motherboard is what pulls it in; the trade-off is marginally higher idle GPU power.
- **Prevent (browser side, not declared):** turning Brave's own GPU acceleration off is a profile setting (`brave://settings/system`), and nothing in the flake sets it. To make it declarative, add the flag to the `wrapProgram … --add-flags` list in `mynixos/my/users/apps/browsers/brave/default.nix` — this host runs that wrapper (`brave-with-gopass`), and the nixpkgs Brave takes flags from its wrapper (or the package's `commandLineArgs` argument); there is no flags file it reads.
- **Recover:** Hyprland restarts itself; vogix-input self-heals onto the new instance (P1). Longer-term: a reset-recovery compositor (sway/wlroots) survives the reset entirely.

---

## PREVENT pillar (mynixos, declarative — so P2/P3 stay rare)
- **`user@.service` OOM-immunity.** `my.performance.enable` installs a drop-in (`overrideStrategy = "asDropin"`) carrying `OOMScoreAdjust=-900` and `ManagedOOMPreference=avoid` — `mynixos/my/performance/default.nix`. `-900` rather than `-1000` because the kernel inherits `-1000` to unprivileged children, which then cannot raise it back. `ManagedOOMPreference` steers systemd-oomd, a separate killer, which `my.system.enable` turns on together with its root and user slices (`mynixos/my/system/core/default.nix`). Both Linux hosts set `performance.enable = true`; the option is declared only on Linux.
- **Cap the dev/build work** so a runaway can't global-OOM: a memory-capped slice (`MemoryHigh`/`MemoryMax`/`OOMPolicy=kill`) with heavy builds run inside it (`systemd-run --user --slice=…`). Not in mynixos yet — this is the remaining gap.
- **Cap `pr4xis-domains` test parallelism** (the trigger): `cargo nextest run -p pr4xis-domains -j4` — each test process loads the full corpus, ~4.4 GB.

## RECOVER pillar (`vogix recover` — codifies P1–P3 as a command)
Planned: reconcile the live session against the desired set — detect dead/orphaned/stranded units → re-import env → kill orphans + `reset-failed` → restart the cohort → re-attach the input engine. The reconcile logic belongs in the vogix crate and stays portable (no systemd words leak in); the systemd specifics stay in vogix's Nix modules (`nix/modules/nixos.nix`, `nix/modules/home-manager`). `scripts/recover-session.sh` is the stopgap until then.
