# claude-code pinned to 2.1.235, overriding whatever the nixpkgs pin ships.
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
      version = "2.1.235";
      platforms = {
        "darwin-arm64".checksum = "83b8f806f6f2eea316cfe246628e6c23374711d868f1fd0409db551b877b7748";
        "darwin-x64".checksum = "325a2dbc166ba8361a913ce588dce4a236789502060239acea52072bb51a54f1";
        "linux-arm64".checksum = "cff9592faa292db0f6ac21874f151b8c3d44e23bf0ab9fd1bcca95edc3469549";
        "linux-arm64-musl".checksum = "c852a47a50db72560a779240a0a9b86ef38cc1453ab5268228f6519e0eb231de";
        "linux-x64".checksum = "bfcf0ae2dbf94b2b6a106074aabf3938b9a10889c3b678e4cb5a00c03274d5d5";
        "linux-x64-musl".checksum = "6aae801d8f9d31d372e2152cab17d582941d94be03cfcd63328bb4436f0e0385";
        "win32-arm64".checksum = "8709594f6daebfef9a03ab56401600cfd1d0a980c640daf30d6de6f7cf3f42fe";
        "win32-x64".checksum = "6786fa5d75a64260de09a3b5f88cd4644dc4292e45a38a4df93dc7eb4d0df3fb";
      };
    };
  };
}
