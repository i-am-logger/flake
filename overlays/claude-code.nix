# claude-code pinned to 2.1.251, overriding whatever the nixpkgs pin ships.
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
      version = "2.1.251";
      platforms = {
        "darwin-arm64".checksum = "625869b01e0050f260b2980fac248fd9cef9e462612bded4ec9d3d49ff8969a5";
        "darwin-x64".checksum = "44221d72a3f35772faa85ad9a36a678084a516f720e64b45e26eb9015315500b";
        "linux-arm64".checksum = "65445bd4dd042079cc3fa43791b561370a05c8599e8ec47580e25a81050abbdd";
        "linux-arm64-musl".checksum = "165f6236abf5b0c42892b164c2299c82023421805e0c3eaddf925a3195513f84";
        "linux-x64".checksum = "fd5f10ff0eb58daec04900466b143ea98aab50abf208a422bc008eaec13f61f7";
        "linux-x64-musl".checksum = "5056970c13f46dd2bff2c44dd2a7f766553a63392615412d5711278264730e07";
        "win32-arm64".checksum = "89e91fed2dc6f6278fa1e179e6401c0a1c252fe80c57ee47f17f10f7f7b4e99c";
        "win32-x64".checksum = "8d1229a281281b98fd2dee72b3253a704be4fce4d45207200cd32a9bb5a6c909";
      };
    };
  };
}
