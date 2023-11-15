{ pkgs, ... }:

{
  home.packages = with pkgs; [
    (pkgs.python3Packages.buildPythonPackage rec {
      pname = "pyprland";
      version = "1.4.3";
      format = "pyproject";
      src = pkgs.fetchPypi
        {
          inherit pname version;
          sha256 = "sha256-8cUk2hEdvpUWPKFxuPEVgagIDGtZYJ5Ece+pBYC8yoE=";
        };
      propagatedBuildInputs = with pkgs; [
        python3Packages.setuptools
        python3Packages.poetry-core
        poetry
      ];
      doCheck = false;
    })
  ];
}
