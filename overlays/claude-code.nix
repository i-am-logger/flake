# claude-code pinned to 2.1.280, overriding whatever the nixpkgs pin ships.
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
      version = "2.1.280";
      platforms = {
        "darwin-arm64" = { binary = "claude.zst"; checksum = "214fafd9d60bc0397cb68747b765ab752be4b53303c176ad885c4cafbe30826f"; };
        "darwin-x64" = { binary = "claude.zst"; checksum = "2b5ca074d02ea5dd507db0a90ba55847e297061ca3e987ddc49ea89ae0ff2e7e"; };
        "linux-arm64" = { binary = "claude.zst"; checksum = "6a01f30418f35122a672ccf74bed64aba5119ad47c71548a3b447cc9fec48c81"; };
        "linux-arm64-musl" = { binary = "claude.zst"; checksum = "32dbe8a94da9689791688e0febfb88c39897ad67f055853e7ae1b6d11c4b4e39"; };
        "linux-x64" = { binary = "claude.zst"; checksum = "27910e2ae704d8f2e8024897d8fdf1e7710807baf4f6982c0e3797c058315384"; };
        "linux-x64-musl" = { binary = "claude.zst"; checksum = "2b2e206987e357997bf5c06baf697379b5980a7cc6f1462ca70a6757ece58890"; };
        "win32-arm64" = { binary = "claude.exe.zst"; checksum = "705dccf9d924d471e32efa19157283da2cdd0b8cfc71d7e0a9e3ec4d13ac381b"; };
        "win32-x64" = { binary = "claude.exe.zst"; checksum = "cb50dbe5b595b52925d753b10d5907748a4137e7f0bff84d03ea60cd9a28eaf9"; };
      };
    };
  };
}
