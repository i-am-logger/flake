{ pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    # Ironbar from flake input
    inputs.ironbar.packages.${pkgs.system}.default
    
    # Dependencies
    font-awesome
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.jetbrains-mono
    blueman
    papirus-icon-theme
    adwaita-icon-theme
    
    # System monitoring tools
    lm_sensors
    upower
  ];

  # Copy configuration files
  xdg.configFile."ironbar/" = {
    source = ./config;
    recursive = true;
  };

  # Copy scripts and make them executable
  xdg.configFile."ironbar/scripts/weather.sh" = {
    source = ./scripts/weather.sh;
    executable = true;
  };

  xdg.configFile."ironbar/scripts/privacy.sh" = {
    source = ./scripts/privacy.sh;
    executable = true;
  };

  xdg.configFile."ironbar/scripts/cava.sh" = {
    source = ./scripts/cava.sh;
    executable = true;
  };

  xdg.configFile."ironbar/scripts/memory.sh" = {
    source = ./scripts/memory.sh;
    executable = true;
  };

  xdg.configFile."ironbar/scripts/cpu.sh" = {
    source = ./scripts/cpu.sh;
    executable = true;
  };

  xdg.configFile."ironbar/scripts/temperature.sh" = {
    source = ./scripts/temperature.sh;
    executable = true;
  };

  xdg.configFile."ironbar/scripts/network-bandwidth.sh" = {
    source = ./scripts/network-bandwidth.sh;
    executable = true;
  };

  xdg.configFile."ironbar/scripts/keyboard-state.sh" = {
    source = ./scripts/keyboard-state.sh;
    executable = true;
  };

  xdg.configFile."ironbar/scripts/audio-viz.sh" = {
    source = ./scripts/audio-viz.sh;
    executable = true;
  };

  # Systemd service for ironbar
  systemd.user.services.ironbar = {
    Unit = {
      Description = "Ironbar status bar";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${inputs.ironbar.packages.${pkgs.system}.default}/bin/ironbar";
      Restart = "on-failure";
      RestartSec = 3;
    };

    Install = {
      WantedBy = [ "hyprland-session.target" ];
    };
  };
}
