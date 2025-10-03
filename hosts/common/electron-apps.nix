{ pkgs, ... }:
let
  # Helper function to wrap Electron apps
  # TODO: Re-enable libsecret when pass-secret-service is properly configured
  wrapElectronApp = pkg: bin: pkgs.symlinkJoin {
    name = "${pkg.pname or pkg.name}-wrapped";
    paths = [ pkg ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/${bin} \
        --add-flags "--password-store=basic"
    '';
  };
in
{
  # Allow unfree packages for Electron apps
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (pkg.pname or pkg.name) [
      "slack"
      "signal-desktop"
    ];

  # Install wrapped Electron apps
  environment.systemPackages = [
    (wrapElectronApp pkgs.slack "slack")
    (wrapElectronApp pkgs.signal-desktop "signal-desktop")
  ];
}
