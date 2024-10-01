{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.wlsunset ];

  # Wlsunset service
  systemd.user.services.wlsunset = {
    description = "Wayland Night Light";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.wlsunset}/bin/wlsunset -l 39.739235 -L -104.990250";
      Restart = "always";
      RestartSec = 3;
    };
  };
}
