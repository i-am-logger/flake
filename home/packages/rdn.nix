{ pkgs }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "rdn";
  version = "0.1.0-unstable-2025-06-08";

  src = pkgs.fetchFromGitHub {
    owner = "apatrushev";
    repo = "rdn";
    rev = "c43cd781543aab3d7a24be4f7c92614a75b3e450";
    hash = "sha256-o38TC2tSSYEL8EauWXCo5SyKQ2/F4i3+3nNGw+Qtg5U=";
  };

  cargoHash = "sha256-UhEWbcOC/81v6J4QlPPfn1zYN3PZ76MG+VHFuHFdkS4=";

  meta = with pkgs.lib; {
    description = "A modern two-panel file manager inspired by Dos Navigator";
    homepage = "https://github.com/apatrushev/rdn";
    license = licenses.mit;
    mainProgram = "rdn";
  };
}
