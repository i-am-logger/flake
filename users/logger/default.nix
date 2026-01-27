# User configuration for: logger (Ido Samuelson)
# This file centralizes user data to avoid duplication across systems
{
  fullName = "Ido Samuelson";
  description = "whistleblower";
  # Password is managed via sops-nix (see secrets.yaml)
  secrets.hashedPassword = true;
  shell = "bash";
  avatar = ./avatar.png;
  email = "i-am-logger@users.noreply.github.com";
  github = {
    username = "i-am-logger";
    repositories = [ ]; # Empty for now, will be set in system configs
  };
  yubikeys = import ./yubikeys.nix;

  # Application preferences now use the mynixos app system (my.users.<name>.apps.*)
  # and environment API (environment.*) below

  # Environment API - named after environment variables they set
  environment = {
    # Use mynixos opinionated defaults (uncomment to override)
    # BROWSER = pkgs.brave;       # Sets BROWSER env var
    # TERMINAL = pkgs.wezterm;    # Sets TERMINAL env var
    # EDITOR = pkgs.helix;        # Sets EDITOR and VISUAL env vars
    # SHELL = pkgs.bash;          # Sets SHELL env var
    # FILE_MANAGER = pkgs.yazi;   # Sets FILE_MANAGER env var
    # launcher = pkgs.walker;     # Application launcher (no standard env var)
    # multiplexer = pkgs.zellij;  # Terminal multiplexer (no standard env var)
  };

  # User-level feature flags (mynixos provides opinionated defaults)
  # These can be overridden per-system in systems/*/default.nix

  # Feature flags: graphical, dev, ai
  # Auto-enable system features when user has these enabled
  graphical = {
    enable = true; # Enables Hyprland, webapps, etc.
    streaming = {
      enable = true; # Enables OBS (nested under graphical)
    };
    webapps = {
      enable = true; # mynixos opinionated defaults apply
      # Override specific ones here or in system config if needed
    };
    media = {
      enable = true; # Enable media apps with opinionated defaults
      # Defaults: mypaint, krita, gimp, inkscape, pipewireTools, audioUtils = true
      # Heavy apps (blender, darktable) = false unless explicitly enabled
    };
  };

  # Application configuration (category structure: apps.{feature}.{category}.{app})
  apps = {
    graphical.windowManagers.hyprland = {
      enable = true; # mynixos default, auto-enabled when graphical = true
      # User-specific input preferences (override generic defaults)
      leftHanded = true; # User is left-handed
      sensitivity = -0.3; # User's preferred mouse sensitivity
      # browser/terminal now come from environment API automatically
    };

    security.passwords.onePassword.enable = true; # 1Password password manager
  };

  dev = {
    enable = true; # Enables development tools
    docker = {
      enable = true; # Opinionated default
    };
  };

  ai = {
    enable = true; # Enables AI features
  };

  terminal = {
    enable = true; # Enable terminal tools
    multiplexer = "zellij"; # Default, can override to "tmux", "screen", or "none"
    # Defaults: yazi, fastfetch, bat, lsd = true
    # Others disabled unless explicitly enabled
  };

  # Theme configuration via vogix
  themes.vogix = {
    scheme = "base16";
    theme = "catppuccin";
    variant = "mocha";
  };
}
