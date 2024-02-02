{ pkgs, ... }: {

  environment.systemPackages = with pkgs; [
    chkrootkit # https://github.com/NixOS/nixpkgs/issues/285643
  ];
}
