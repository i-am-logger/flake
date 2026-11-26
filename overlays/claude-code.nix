# claude-code pinned to 2.1.332, overriding whatever the nixpkgs pin ships.
# Auto-updated by scripts/update-claude-code.sh; edit that, not this file.
#
# Upstream ships one native binary per platform plus a release manifest
# listing their checksums, and the nixpkgs derivation takes that manifest as
# an argument. So a version bump overrides exactly one thing: no hand-rolled
# derivation, no per-platform wrapping to keep in sync with upstream's, and
# one overlay that serves x86_64-linux and aarch64-darwin alike -- all three
# hosts import it, and all three land on the same version.
#
# The derivation reads three things out of a manifest: `version`, which is
# half the download URL, `platforms.<key>.binary`, which is the other half,
# and `platforms.<key>.checksum`. All three are mirrored below; only
# upstream's `size` is dropped. `binary` used to be dropped too, because the
# derivation hardcoded the filename -- until it stopped, and every host that
# imports this overlay failed to evaluate with "attribute 'binary' missing".
# Mirror what upstream sends rather than assuming a filename. <key> comes from
# hostPlatform.node, which encodes OS and CPU but not libc, so only
# darwin-arm64, linux-arm64 and linux-x64 can ever be selected here -- the
# musl and win32 rows are mirrored for fidelity and are unreachable.
#
# The Linux binaries are Bun single-file executables, but not the appended
# kind: the payload is a mapped .bun section, and the section header table
# ends exactly at EOF with nothing following it (measured on the linux-x64
# artifact). So the patchelf upstream runs on every ELF has no end-of-file
# offset to disturb, and this overlay no longer hand-rolls a derivation to
# route around one, as its predecessor did on that theory. What upstream does
# guard against is stripping, which it says leaves Bun running as a plain
# runtime instead of the app: hence dontStrip, plus a `claude --version`
# check against the packaged version at build time, so a binary broken that
# way fails the build rather than reaching a shell.
#
# To wind this down once the nixpkgs pin catches up, delete this file and
# every `(import ../../overlays/claude-code.nix)` line under systems/ --
# yoga, skyspy-dev, ads-dev1 and aether5d-dev today.
_final: prev:
{
  claude-code = prev.claude-code.override {
    manifest = {
      version = "2.1.332";
      platforms = {
        "darwin-arm64" = { binary = "claude.zst"; checksum = "8a4cbdcb6279039c5584562a75154a818f622476c8e46de1f9ae1cbe40c12859"; };
        "darwin-x64" = { binary = "claude.zst"; checksum = "b3b85859ab1151dae1c0c2e17f7f4e958a3ad73e00224b8655c1cb71abcc192a"; };
        "linux-arm64" = { binary = "claude.zst"; checksum = "b76015ad1663566187a721e5641f6190722c0d2f95bfc35ff42ef4781fae0fa3"; };
        "linux-arm64-musl" = { binary = "claude.zst"; checksum = "03aecafd85b1f8668bb50bbb18ca5745e68b83c7ba38064dd2acce5d6e0afa5f"; };
        "linux-x64" = { binary = "claude.zst"; checksum = "e9f53728e093fb9bea7e9c75094b6cfd7e6a82ee3791efbbf22238d6695f6220"; };
        "linux-x64-musl" = { binary = "claude.zst"; checksum = "d8af975627cf41dea803f68aa04890949cb622d197a5306566489f72ee757553"; };
        "win32-arm64" = { binary = "claude.exe.zst"; checksum = "46e49f9eb07aa817e24ffd378347fd1bd16dceec63cb79766a8ff1833d949f16"; };
        "win32-x64" = { binary = "claude.exe.zst"; checksum = "afa8b6fb4a90f7ba95d3719db840abf2477f32dbfeb7c6a16bfc07a38fa147c0"; };
      };
    };
  };
}
