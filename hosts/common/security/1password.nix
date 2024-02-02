{ lib, ... }: {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "1password-gui"
      "1password"
      "1password-cli"
    ];

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # polkitPolicyOwners = ["snick"];
  };
}
