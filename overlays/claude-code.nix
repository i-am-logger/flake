# claude-code pinned to 2.1.248, overriding whatever the nixpkgs pin ships.
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
      version = "2.1.248";
      platforms = {
        "darwin-arm64".checksum = "a3f276daa51919f378bcd797d44f8e3d09653c2858123157d272de38952efeef";
        "darwin-x64".checksum = "35c21b09d049a4d040c511cd9f73de01df83aa1d4b35a43ae1353bde413b42bc";
        "linux-arm64".checksum = "76655a3731274f36236632b9acbcb9bef7055de20041c411b761856043fbc0df";
        "linux-arm64-musl".checksum = "ca9cabd7c636889de73c399d31be4f115fd2737c64482ada7bf4b1c0d51448f3";
        "linux-x64".checksum = "3edee3cb054bd6823674fd60d5c0e442825b28ee8fbf815af2d16bf0de072e16";
        "linux-x64-musl".checksum = "155e1aa56d0c7e2aaae92788c414e7c43315220289bbd38f7a89ba33d07ff48f";
        "win32-arm64".checksum = "d3ee9756700a4e7642216e04f1a57baba9633732de9d85a4b7918c4731e4b572";
        "win32-x64".checksum = "c322169422b45ec4bbfeae3aae6cfd6367a622b0d12f06ba9766e18bb8eca2af";
      };
    };
  };
}
