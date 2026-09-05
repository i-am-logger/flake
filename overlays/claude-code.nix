# claude-code pinned to 2.1.260, overriding whatever the nixpkgs pin ships.
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
      version = "2.1.260";
      platforms = {
        "darwin-arm64" = { binary = "claude.zst"; checksum = "90c8e9f337f7461b7582862f35ce22f89ad13b8d529c150f2969e8fa6d3bf020"; };
        "darwin-x64" = { binary = "claude.zst"; checksum = "6f85206e0365f2edbcaff94058802d627d5c48d585d5630cf71e5fe1515f3e00"; };
        "linux-arm64" = { binary = "claude.zst"; checksum = "cfd17d6812c2bd7c2e9c4bc028786e5619db2962a17ac10b77667a3ff1148877"; };
        "linux-arm64-musl" = { binary = "claude.zst"; checksum = "b483ac78a8f2169a744703f273ed24b302baf8b671c92897a7611f107f6c3920"; };
        "linux-x64" = { binary = "claude.zst"; checksum = "ad1c0b3f2de334f4bcb4a783c275b1af7a5945c0c955a9c7352cf4fa0666a7ec"; };
        "linux-x64-musl" = { binary = "claude.zst"; checksum = "0d4231f3bafbc88f26899e54c246638659feccfb7e8be7b0d02078b58bdd4039"; };
        "win32-arm64" = { binary = "claude.exe.zst"; checksum = "f38cd767f8aef8c0eec1a09bf1f636bf9c6b8589d133c80be54a3ec9798a0f18"; };
        "win32-x64" = { binary = "claude.exe.zst"; checksum = "664d2c6ca08afcd030100ddaddb80c5764bc517a4df407d819e6839bcc5edca8"; };
      };
    };
  };
}
