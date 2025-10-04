{ config, pkgs, ... }:

{
  # Configure extensions for Chromium-based browsers (including Brave)
  programs.chromium = {
    enable = true;
    extensions = [
      # "naepdomgkenhinolocfifgehidddafch"  # Browserpass CE extension (disabled)
      "aeblfdkhhhdcdjpifhhbdiojplfjncoa"  # 1Password extension
    ];
  };
}