{ pkgs, ... }:
{

  # environment.systemPackages = with pkgs; [
  # ];

  # Enable wshowkeys to access input events
  security.wrappers.wshowkeys = {
    owner = "root";
    group = "root";
    setuid = true;
    source = "${pkgs.wshowkeys}/bin/wshowkeys";
  };

  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "8192";
    }
  ];
}
