{ ... }:
{
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
    "x-scheme-handler/unknown" = "brave";
  };

  environment.sessionVariables.DEFAULT_BROWSER = "brave";

  environment.pathsToLink = [ "libexec" ];
}
