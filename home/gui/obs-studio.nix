{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ffmpeg-full
    twitch-tui # twitch chat in terminal
    streamlink # streamlink for live videostream
  ];
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      # obs-backgroundremoval
      obs-teleport
      obs-tuna
      waveform
      # input-overlay # displays keyboard/mouse inputs - causes segmentation fault
      obs-text-pthread # rich text source plugin for custom text overlays
      # obs-v4l2sink # virtual camera support - not available in nixpkgs
      # droidcam-obs
      advanced-scene-switcher # automated scene switcher with hotkey support
      # obs-source-record
    ];
  };
}
