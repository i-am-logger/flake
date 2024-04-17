# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ ... }: {
  environment.variables = {
    EDITOR = "hx";
    VIEWER = "hx";
    BROWSER = "brave";
    DEFAULT_BROWSER = "brave";
  };

  xdg.mime.defaultApplications = {
    "text/html" = "brave";
    "x-scheme-handler/http" = "brave";
    "x-scheme-handler/https" = "brave";
    "x-scheme-handler/about" = "brave";
    # "x-scheme-handler/unknown" = "firefox";
  };

  environment.sessionVariables.DEFAULT_BROWSER = "brave";

  environment.pathsToLink = [ "libexec" ];

  programs.fish.enable = true;
}
