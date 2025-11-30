{ pkgs
, ...
}:
{
  powerManagement = {
    enable = true;
  };
  networking.interfaces.enp118s0.wakeOnLan.enable = false;
  networking.networkmanager.wifi.powersave = true;

  services.logind.lidSwitchExternalPower = "ignore";

  services.upower = {
    enable = true;
  };

  programs.light.enable = true;

  # https://github.com/johnfanv2/LenovoLegionLinux
  environment.systemPackages = with pkgs; [
    acpi
    lm_sensors
  ];
}
