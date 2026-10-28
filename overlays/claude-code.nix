# claude-code pinned to 2.1.312, overriding whatever the nixpkgs pin ships.
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
      version = "2.1.312";
      platforms = {
        "darwin-arm64" = { binary = "claude.zst"; checksum = "7d759495d011057b6e8b8ee911c5be3cd36e9491c71a4ab194a425cdb1418073"; };
        "darwin-x64" = { binary = "claude.zst"; checksum = "14e650c4383c00c23cdb2ff9e5b277d6248031adfbbaf1208876edb692b7dd3f"; };
        "linux-arm64" = { binary = "claude.zst"; checksum = "863ee1d2a91a39ee22fa13322582e4c3fb45bfb4739b22ec7e396dde694d8581"; };
        "linux-arm64-musl" = { binary = "claude.zst"; checksum = "5e8714a8944f6771325a8b2bd641bcdca7bcc632d60b4b965f8c716db989a6cc"; };
        "linux-x64" = { binary = "claude.zst"; checksum = "6fb9e329947c003740be888f98db1aecaa238d6c7d9ceef8581eb71d5a59480b"; };
        "linux-x64-musl" = { binary = "claude.zst"; checksum = "122b51ddadc68c6afc8deb4d7bda82fcb5e1d49e5994c3eed750a5d6428ab6a4"; };
        "win32-arm64" = { binary = "claude.exe.zst"; checksum = "dc3fd34fc9d523e6a94702e051998db52afd1d647132f61fd3daa246022ffcf9"; };
        "win32-x64" = { binary = "claude.exe.zst"; checksum = "c5e376352bf2b0e56592358ba3b2943d3de7b351f750c2340f0675fe88148038"; };
      };
    };
  };
}
