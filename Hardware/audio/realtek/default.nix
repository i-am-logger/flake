{ config, lib, pkgs, ... }:

{
  options.hardware.audio = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable audio support";
    };
    
    model = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Specific audio model (e.g., 'realtek-alc4080')";
    };
  };

  config = lib.mkIf config.hardware.audio.enable {
    # Realtek audio driver configuration

    # Enable sound with pipewire
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };
}
