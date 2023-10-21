# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{...}: {
  environment.variables = {
    EDITOR = "hx";
    VIEWER = "hx";
    BROWSER = "firefox";
    DEFAULT_BROWSER = "firefox";
  };

  xdg.mime.defaultApplications = {
    "text/html" = "firefox";
    "x-scheme-handler/http" = "firefox";
    "x-scheme-handler/https" = "firefox";
    "x-scheme-handler/about" = "firefox";
    "x-scheme-handler/unknown" = "firefox";
  };

  environment.sessionVariables.DEFAULT_BROWSER = "firefox";

  environment.pathsToLink = ["libexec"];

  programs.fish.enable = true;
}
