{
  pkgs,
  ...
}:
{
  boot.loader.grub.configurationLimit = 100;
  boot.tmp.cleanOnBoot = true;

  nix = {
    settings = {
      max-jobs = "auto";
      cores = 0; # auto detect
      build-cores = 0;
      # parallel-builds = true;
      sandbox = true;
      # download-buffer-size = 4 * 1024 * 1024 * 1024;
      system-features = [
        # "cuda"
        "big-parallel"
      ];

      extra-platforms = [
        "x86_64-linux"
        # "cuda"
      ];

      trusted-users = [
        "root"
        "logger"
      ];
      substituters = [
        #   "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        "https://cache.nixos.org/"
      ];
      auto-optimise-store = true; # Optimise syslinks
      # sandbox - an isolated environment for each build process. It is used to remove further hidden dependencies set by the build environment to improve reproducibility.
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    package = pkgs.nixVersions.latest;
    #registry.nixpkgs.flake = inputs.nixpkgs;
    # experimental-features = nix-command flakes auto-allocate-uids configurable-impure-env
    extraOptions = ''
      experimental-features = nix-command flakes auto-allocate-uids
      keep-outputs          = false
      keep-derivations      = false
      extra-substituters = https://devenv.cachix.org
      extra-trusted-public-keys = devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=
    '';
  };
}
