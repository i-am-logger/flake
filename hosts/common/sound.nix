# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, ... }:
{
  # defaults.pcm.!card "AUDIO"
  # defaults.ctl.!card "AUDIO"{
  # Enable sound with pipewire.
  hardware.pulseaudio.package = pkgs.pulseaudioFull;
  
  # boot.extraModprobeConfig = ''
  #   options snd-intel-dspcfg dsp_driver=1
  # '';
  sound = {
    enable = true;
    # extraConfig = ''
    #   pcm.!default {
    #     type hw
    #     card 0
    #   }
      
    #   ctl.!default {
    #     type hw           
    #     card 0
    #   }
    # '';
  };
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true; # Realtime audio support
  services.pipewire = {
    enable = true;
    audio.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    # If you want to use JACK applications, uncomment this
    # jack.enable = true;

  };
}
