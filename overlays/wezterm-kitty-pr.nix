# Build wezterm from the kitty image branch instead of the nixpkgs pin.
#
# Upstream PR: https://github.com/wezterm/wezterm/pull/8061
# Branch: i-am-logger/wezterm @ kitty-image-shm-and-hashing
#
# The branch fixes the kitty `t=s` shared memory transport, which never drew on
# macOS because a POSIX shared memory object can only be mapped there, and cuts
# the per-frame image hashing cost. Drop this file once the PR lands and the
# nixpkgs pin moves past it.
#
# The branch changes Cargo.lock, so cargoDeps has to be re-vendored alongside
# src; overriding src on its own leaves the vendor directory built from the
# nixpkgs revision's lockfile.
_final: prev:
let
  rev = "fba3b958b96d03983919ca07333a424034e7c2be";
in
{
  wezterm = prev.wezterm.overrideAttrs (old: rec {
    version = "0-unstable-kitty-image-pr8061";

    src = prev.fetchFromGitHub {
      owner = "i-am-logger";
      repo = "wezterm";
      inherit rev;
      fetchSubmodules = true;
      hash = "sha256-N+T2rJS6w3oDCKRz7e47Df+gwEscccdfmq00ZRZKpo8=";
    };

    cargoDeps = prev.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-MVFgzMTkK0GKdIu0QdxpZfi6mOjyjyvv9xfcMWafBEU=";
    };

    # The nixpkgs postPatch writes finalAttrs.version into .tag, which the build
    # reads as the reported version. overrideAttrs does not reach finalAttrs, so
    # restate it against the version above.
    postPatch = builtins.replaceStrings [ old.version ] [ version ] old.postPatch;
  });
}
