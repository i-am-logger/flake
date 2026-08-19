# herdr pinned to 0.8.2, ahead of the 0.7.5 nixpkgs ships.
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
#
# Everything else -- the zig hook wiring, the darwin cctools/xcbuild inputs,
# the shell completions and SKILL.md generated in postInstall -- is inherited
# from nixpkgs, which is the point of overriding rather than vendoring the
# recipe: nixpkgs' fixes keep arriving.
#
# Delete this file and its import in systems/*/default.nix once nixpkgs ships
# 0.8.2 or newer. Running scripts/update-herdr.sh will say so when that day
# comes, and will refuse to write an overlay that is not ahead.
_final: prev:
let
  version = "0.8.2";

  src = prev.fetchFromGitHub {
    owner = "herdrdev";
    repo = "herdr";
    tag = "v${version}";
    hash = "sha256-sEGIN3dLZasaHob3EHscWBCIQHflMQVchYmzgsETDk4=";
  };
in
{
  herdr = prev.herdr.overrideAttrs (_old: {
    inherit version src;

    cargoDeps = prev.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-4VThqPwYYEsGvaOKjBeL6XAC5bnNWB6oUMWP/uXc/UQ=";
    };

    zigDeps = prev.zig_0_15.fetchDeps {
      pname = "herdr";
      inherit version;
      src = "${src}/vendor/libghostty-vt";
      fetchAll = true;
      hash = "sha256-PnM+hZIlLyQwK8vJgd/Bhjt1lNIz06T8FahwliRmMrY=";
    };
  });
}
