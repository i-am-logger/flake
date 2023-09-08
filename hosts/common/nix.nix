{
  config,
  pkgs,
  lib,
  user,
  ...
}: {
  boot.loader.grub.configurationLimit = 2;
  boot.tmp.cleanOnBoot = true;

  nix = {
    settings = {
      substituters = [
        #   "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        #   "https://cache.nixos.org/"
      ];
      auto-optimise-store = true; # Optimise syslinks
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 2d";
    };
    package = pkgs.nixVersions.unstable;
    #registry.nixpkgs.flake = inputs.nixpkgs;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs          = true
      keep-derivations      = true
    '';
  };
}
