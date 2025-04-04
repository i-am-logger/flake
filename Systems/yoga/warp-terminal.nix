{ pkgs, ... }:

let
  warp-latest-version = "0.2025.04.02.08.11.stable_03";
  warp-latest-hash = "sha256-wHiiKgTqAC30VMH0VhslmaNZyCwYEs6N915jlkxL8d8=";

  warp-version = warp-latest-version;
  warp-hash = warp-latest-hash;
  #
  warp-custom = pkgs.warp-terminal.overrideAttrs (oldAttrs: {
    version = warp-version;
    src = pkgs.fetchurl {
      url = "https://releases.warp.dev/stable/v${warp-version}/warp-terminal-v${warp-version}-1-${
        if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then "x86_64" else "aarch64"
      }.pkg.tar.zst";
      hash = warp-hash;
    };
  });
in
{
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (pkg.pname or pkg.name) [
      "warp-terminal"
    ];

  environment.systemPackages = [
    warp-custom
  ];

  environment.sessionVariables = {
    WARP_ENABLE_WAYLAND = 0;
  };

  # Configure persistence for warp-terminal
  # environment.persistence."/persist" = {
  #   users.logger = {
  #     directories = [
  #       ".config/warp-terminal"
  #       ".local/state/warp-terminal"
  #     ];
  #   };
  # };
}
