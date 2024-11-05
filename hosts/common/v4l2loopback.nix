{ config, ... }:
{
  boot.kernelModules = [ "v4l2loopback" ];

  boot.extraModulePackages = [
    config.boot.kernelPackages.v4l2loopback
  ];

  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=1 card_label="My OBS Virt Cam" exclusive_caps=1
  '';
  security.polkit.enable = true;

  # subject.isInGroup("users")
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.policykit.exec" &&
            action.lookup("program") == "/run/current-system/sw/bin/modprobe" &&
            subject.isInGroup("users")) {
            return polkit.Result.YES;
        }
    });
  '';

  services.usbmuxd.enable = true;
}
