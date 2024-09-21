{ pkgs, ... }: {
  home.packages = with pkgs; [
    ffmpeg-full
  ];
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [

      # for terminal fun
      pkgs.twitch-tui # twitch chat in terminal
      pkgs.streamlink # streamlink for live videostream
      wlrobs
      # obs-backgroundremoval
      obs-teleport
      obs-tuna
      waveform
      # droidcam-obs
      # advanced-scene-switcher
      # obs-source-record
    ];
  };
}
