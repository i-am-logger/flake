# claude-code pinned to 2.1.237, overriding whatever the nixpkgs pin ships.
# Auto-updated by scripts/update-claude-code.sh; edit that, not this file.
#
# Upstream ships one native binary per platform plus a release manifest
# listing their checksums, and the nixpkgs derivation takes that manifest as
# an argument. So a version bump overrides exactly one thing: no hand-rolled
# derivation, no per-platform wrapping to keep in sync with upstream's, and
# one overlay that serves x86_64-linux and aarch64-darwin alike -- all three
# hosts import it, and all three land on the same version.
#
# The derivation reads two things out of a manifest: `version`, which is also
# half the download URL, and `platforms.<key>.checksum`. Both are mirrored
# below; upstream's `binary` and `size` are dropped. <key> comes from
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
      version = "2.1.237";
      platforms = {
        "darwin-arm64".checksum = "338901351d4ff17495738c67fc3e12a32c1b506738ac5e012eb782d3d8b5be43";
        "darwin-x64".checksum = "9f00789754a7b95febc6d4e37a3b6523d4d9c4c2333a2ce4bd596ad82186224e";
        "linux-arm64".checksum = "a701cfb6bb4703abc6f3ce47508c878ca8158ebdbeacd5c35c7d510c7bc70177";
        "linux-arm64-musl".checksum = "60d832e81dd5076333e9f91286f660f2aaacc630079863599555caa8fe134eba";
        "linux-x64".checksum = "73975167f0108693cf6fd6614994781657ebb8456ebef5d247458734abfb3916";
        "linux-x64-musl".checksum = "b2c81ba8f2b0086b2536a56bf074bbf643043c2bd1aeea6ac8905709ae296168";
        "win32-arm64".checksum = "35978113ca98721cbf14c3abac90482d467419b9669d849c89d91c5664a5f95d";
        "win32-x64".checksum = "406167231b3636e55a01d0ce93567256c61e7973489e645883302f14808ae668";
      };
    };
  };
}
