# herdr pinned to 0.9.1, ahead of the 0.9.0 nixpkgs ships.
# Auto-updated by scripts/update-herdr.sh; edit that, not this file.
#
# herdr is built from source, so unlike overlays/claude-code.nix this cannot
# be a one-attribute override. Three things have to move together:
#
#   src        the release tag, and its hash
#   cargoDeps  re-expressed, not inherited. buildRustPackage turns cargoHash
#              into cargoDeps inside its own wrapper, above the finalAttrs
#              fixed point overrideAttrs re-enters, so overriding cargoHash
#              alone leaves the vendor directory built from the old lockfile.
#   zigDeps    re-expressed for the same reason: it is a fixed-output fetch of
#              vendor/libghostty-vt whose hash is a literal in the recipe.
#   zig        the toolchain this release's vendored libghostty-vt names as
#              its minimum (build.zig.zon), which upstream's build.rs enforces.
#              nixpkgs' recipe hardcodes the Zig *its* herdr needed, so the
#              hook in nativeBuildInputs is swapped for zig_0_16's, and
#              zigDeps is fetched with the same Zig.
#
# Everything else -- the darwin cctools/xcbuild inputs, the shell completions
# and SKILL.md generated in postInstall -- is inherited from nixpkgs, which
# is the point of overriding rather than vendoring the recipe: nixpkgs' fixes
# keep arriving.
#
# Delete this file and its import in systems/*/default.nix once nixpkgs ships
# 0.9.1 or newer. Running scripts/update-herdr.sh will say so when that day
# comes, and will refuse to write an overlay that is not ahead.
_final: prev:
let
  version = "0.9.1";

  src = prev.fetchFromGitHub {
    owner = "herdrdev";
    repo = "herdr";
    tag = "v${version}";
    hash = "sha256-N6+kprfWRyh0AkAiopkGsNXUGGORyPVFHEaDHCpGQs8=";
  };

  zig = prev.zig_0_16;
in
{
  herdr = prev.herdr.overrideAttrs (old: {
    inherit version src;

    cargoDeps = prev.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-1VAmsDE3zeU0wMVQKleQcd/zq8/k/oor8tasrsRQfeY=";
    };

    zigDeps = zig.fetchDeps {
      pname = "herdr";
      inherit version;
      src = "${src}/vendor/libghostty-vt";
      fetchAll = true;
      hash = "sha256-Cy0DdSvce+fhOFIfxHMQGF2b2j16UkS27UpGbfC42XI=";
    };

    # Every nixpkgs Zig hook is named zig-<version>, so this drops whichever
    # one the recipe brought and leads with the one this release needs.
    nativeBuildInputs = [ zig.hook ]
      ++ builtins.filter (p: prev.lib.getName p != "zig") old.nativeBuildInputs;
  });
}
