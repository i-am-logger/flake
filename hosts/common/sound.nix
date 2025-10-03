{ pkgs, ... }:
{
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    audio.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # wireplumber.enable = true;
    # jack.enable = true;
  };

  # General audio optimizations
  # (Legion-specific fixes moved to nixos-hardware)

  # Additional audio tools
  environment.systemPackages = with pkgs; [
    alsa-tools
    alsa-utils
  ];
}
