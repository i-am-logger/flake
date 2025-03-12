{ ... }:

{
  # Enable upower
  services.upower.enable = true;

  # Enable auto-cpufreq
  services.auto-cpufreq.enable = true;

  # Explicitly disable TLP to avoid conflicts
  services.tlp.enable = false;

  # You may want to add some configuration for auto-cpufreq
  services.auto-cpufreq.settings = {
    battery = {
      governor = "powersave";
      # turbo = "auto";
    };
    charger = {
      governor = "powersave";
      # governor = "performance";
      # turbo = "auto";
    };
  };
}
