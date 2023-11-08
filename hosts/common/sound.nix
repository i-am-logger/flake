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
  environment.etc = {
    "pipewire/pipewire.conf.d/92-low-latency.conf".text = ''
      context.properties = {
        default.clock.rate = 352800
        # default.clock.quantum = 32
        # default.clock.min-quantum = 32
        # default.clock.max-quantum = 32
      }
    '';
  };
  # environment.etc."wireplumber/main.lua.d/99-alsa-lowlatency.lua".text = ''
  #   alsa_monitor.rules = {
  #     {
  #       matches = {{{ "node.name", "matches", "alsa_output.*" }}};
  #       apply_properties = {
  #         ["audio.format"] = "S32LE",
  #         ["audio.rate"] = "96000", -- for USB soundcards it should be twice your desired rate
  #         ["api.alsa.period-size"] = 2, -- defaults to 1024, tweak by trial-and-error
  #         -- ["api.alsa.disable-batch"] = true, -- generally, USB soundcards use the batch mode
  #       },
  #     },
  #   }
  # '';
}
