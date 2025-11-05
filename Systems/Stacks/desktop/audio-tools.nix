{ config, lib, pkgs, ... }:

{
  options.stacks.desktop.audioTools = {
    enable = lib.mkEnableOption "audio control and debugging tools" // {
      default = true;
    };
  };

  config = lib.mkIf (config.stacks.desktop.enable && config.stacks.desktop.audioTools.enable) {
    environment.systemPackages = with pkgs; [
      alsa-utils    # ALSA utilities (amixer, alsamixer, etc.)
      pavucontrol   # PulseAudio/PipeWire GUI volume control
      pulseaudio    # PulseAudio utilities
    ];
  };
}
