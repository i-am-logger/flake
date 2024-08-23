{ pkgs, ... }: {

  environment.systemPackages = with pkgs; [
    chkrootkit # https://github.com/NixOS/nixpkgs/issues/285643
  ];

  security.pam.loginLimits = [{
    domain = "*";
    type = "soft";
    item = "nofile";
    value = "8192";
  }];
}
