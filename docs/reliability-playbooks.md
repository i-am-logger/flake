# Session reliability playbooks (yoga)

> Principle (user, 2026-06-07): **never reboot to fix something — recover in-session.** Every recovery here was performed live, no re-login. Each playbook = symptom → diagnose → **recover (in-session)** → permanent fix. These are the seed for `vogix recover`. See `project_vogix_session_reliability` (memory) for the verified research grounding.
>
> Shell note: in a degraded session set `export XDG_RUNTIME_DIR=/run/user/$(id -u) DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"` first. Process checks: use `pgrep -f` for `vogix input`/`vogix daemon` (same comm), and remember NixOS wrappers report comm `.NAME-wrapped` (so `pgrep -x waybar`/`-x Hyprland` give false negatives — use `-f` or the systemd unit state).

## P1 — vogix keybindings dead after a Hyprland restart/GPU-reset (stale socket)
- **Symptom:** keys do nothing; `journalctl --user -u vogix-input` shows `dispatch '…' failed: Connection refused (os error 111); will re-discover compositor` on a loop.
- **Cause:** the crashed compositor's `.socket.sock` lingers and the engine's stale `$HYPRLAND_INSTANCE_SIGNATURE` pins it to the dead instance.
- **Recover:** `systemctl --user restart vogix-input` (picks up the live instance from the systemd env).
- **Permanent fix:** SHIPPED — `Hypr::discover()` now connection-tests candidates and self-heals onto the live socket (vogix `9cf6fb9`). Once deployed, P1 auto-resolves on the next keypress.

## P2 — the whole user-service cohort is dead (user@UID.service OOM-killed)
- **Symptom:** no keybindings/bar/audio/idle; `systemctl --user` → `Failed to connect to user scope bus: Connection refused`; `pgrep -u $(id -u) -x systemd` empty.
- **Diagnose:** `systemctl status user@$(id -u).service` → `failed (Result: signal)` / `code=killed`; `journalctl -b -k | grep -iE 'oom|Killed process'` shows the runaway (e.g. `pr4xis_domains-` ~4.4 GB × N).
- **Recover (in-session, no re-login):**
  1. **Stop the runaway first** (or it re-OOMs): identify + kill it (e.g. `pkill -f 'nextest run -p pr4xis-domains'`).
  2. Restart the manager: `systemctl restart user@$(id -u).service` *(needs polkit/sudo — kernel-OOM excludes `user@` from auto-restart, verified #36529; this is the one privileged step until the prevent pillar makes it moot).*
  3. **Re-import the session env** (the revived manager comes up empty): `systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP DISPLAY` then `dbus-update-activation-environment --systemd …` (values from the live Hyprland).
  4. Start the cohort by unit (do **not** `systemctl --user start graphical-session.target` — it's `RefuseManualStart=yes` by design): `systemctl --user start vogix-input vogix-daemon waybar pipewire pipewire-pulse wireplumber`.
  5. Clear any orphaned holders — see **P3**.
- **Permanent fix:** PREVENT pillar (below) — the manager must never be the OOM victim.

## P3 — audio dead / a service stuck `start-limit-hit` (orphaned process holds a lock)
- **Symptom:** `wpctl status` shows zero sinks; `journalctl --user -u pipewire` → `unable to lock lockfile '/run/user/UID/pipewire-0.lock': Resource temporarily unavailable` → `start-limit-hit`.
- **Cause:** a pre-crash process reparented to init survives in the login `session-N.scope` (outliving `user@`) and holds the runtime socket/lock, blocking the systemd unit.
- **Recover (in-session):**
  1. Find + kill the orphan: `ps -e -o pid,ppid,args | grep '[p]ipewire'` → `kill <PID>` (PPID 1, in `session-N.scope`).
  2. Clear stale runtime files if they linger: `rm -f /run/user/$(id -u)/pipewire-0{,.lock,-manager,-manager.lock}`.
  3. `systemctl --user reset-failed pipewire{,.socket} pipewire-pulse{,.socket} wireplumber` *(required — a plain `restart` won't move past start-limit-hit)*.
  4. `systemctl --user restart pipewire.socket pipewire pipewire-pulse.socket pipewire-pulse wireplumber` → `wpctl status` shows sinks.
- **Note:** device ACLs (`/dev/snd`) are logind-owned, keyed to the **active session/seat** (not `user@`) — they survive a manager restart. Seat activation is NOT the blocker; the orphan-lock is.
- **Permanent fix:** the prevent pillar avoids the cohort dying at all; `vogix recover` will fold in orphan-detection + `reset-failed`.

## P4 — Hyprland (and the session) dies on a GPU reset
- **Symptom:** full Hyprland crash/restart; `journalctl -b -k` → `amdgpu … ring gfx timeout → GPU reset succeeded`. Hyprland RASSERT-aborts on any GPU reset (#9746, unimplemented recovery).
- **Trigger:** a userspace GPU shader fault — on yoga, the Brave/Chromium GPU process (verified from the journal decode; see `gpu-igpu-reset-rootcause-2026-06-05.md`). NOT GFXOFF (disproven), NOT BIOS.
- **Prevent:** disable Brave GPU hardware acceleration (`brave://settings` → System, or `~/.config/brave-flags.conf` `--disable-gpu-compositing`).
- **Recover:** Hyprland restarts itself; vogix-input self-heals onto the new instance (P1 fix). Longer-term: a reset-recovery compositor (sway/wlroots) survives the reset entirely.

---

## PREVENT pillar (mynixos, declarative — so P2/P3 become rare/impossible)
- **`user@.service` OOM-immunity:** it currently ships `OOMScoreAdjust=100` (a *preferred* OOM victim — backwards). Set `OOMScoreAdjust=-900` + `ManagedOOMPreference=avoid`.
- **Cap the dev/build work** so a runaway can't global-OOM: a memory-capped slice (`MemoryHigh`/`MemoryMax`/`OOMPolicy=kill`); run heavy builds in it (`systemd-run --user --slice=…`). This is the single change that would have prevented tonight's incident.
- **Cap `pr4xis-domains` test parallelism** (the trigger): `cargo nextest run -p pr4xis-domains -j4` (each test process loads the full corpus ~4.4 GB).

## RECOVER pillar (`vogix recover` — codifies P1–P3 as a command)
Reconcile the live session against the desired set: detect dead/orphaned/stranded units → re-import env → kill orphans + `reset-failed` → restart the cohort → re-attach the input engine. Portable vogix-core logic (no systemd words leak in); the systemd specifics live in nixos-vogix.
