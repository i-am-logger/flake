# claude-code pinned to 2.1.281, overriding whatever the nixpkgs pin ships.
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
# yoga, skyspy-dev and aether5d-dev today.
_final: prev:
{
  claude-code = prev.claude-code.override {
    manifest = {
      version = "2.1.281";
      platforms = {
        "darwin-arm64" = { binary = "claude.zst"; checksum = "056662a4e3a5ca37770730a59345d1b5796ef65444c32b97d236651ab68f3fa1"; };
        "darwin-x64" = { binary = "claude.zst"; checksum = "085dd9952999c742cf262d0fed571c3bcd749d5127eb7dd455bc5be0948c7b9d"; };
        "linux-arm64" = { binary = "claude.zst"; checksum = "7583b65585561c714e18caca45e0e0fb9bdba6d7ed6ee5d5171834d5c657aea6"; };
        "linux-arm64-musl" = { binary = "claude.zst"; checksum = "b5400b7f787e78f6c206c1adf70c65b5b6835f2899b61edfa83a117be92111d5"; };
        "linux-x64" = { binary = "claude.zst"; checksum = "4ffb9f6baada4d88bbd8c586773efd0605c524c7a31cc3833eeda229717a7b25"; };
        "linux-x64-musl" = { binary = "claude.zst"; checksum = "3921fd07a12e93f858c8b706eca0e4d7b12af14f4af5378d3b87254b4231def5"; };
        "win32-arm64" = { binary = "claude.exe.zst"; checksum = "41b632497a440de03904c03483d000b4004b908a5f3eb71f139de6dbd40cd685"; };
        "win32-x64" = { binary = "claude.exe.zst"; checksum = "62f544612ca7e31cdc197bdf8651abcc529bd716964d2517e101177c6b94c70a"; };
      };
    };
  };
}
