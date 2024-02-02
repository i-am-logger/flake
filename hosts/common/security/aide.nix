# https://aide.github.io/
{ pkgs, ... }: {
  environment.systemPackages = [ pkgs.aide ];
  # systemd.timers.skeleton = {
  #   enable = true;
  #   timerConfig = {
  #     OnCalendar = "daily";
  #     Unit = "skeleton.service";
  #   };
  #   wantedBy = [ "timers.target" ];
  # };

  # systemd.services.skeleton = {
  #   enable = true;
  #   serviceConfig.Type = "oneshot";
  #   path = [ pkgs.aide ];
  #   script = ''
  #     # do your stuff with aide
  #   '';
  # };
}
