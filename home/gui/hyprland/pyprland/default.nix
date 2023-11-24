{ pkgs, ... }:

{
  home.packages = with pkgs; [
    (pkgs.python3Packages.buildPythonPackage rec {
      pname = "pyprland";
      version = "1.6.1";
      format = "pyproject";
      src = pkgs.fetchPypi
        {
          inherit pname version;
          sha256 = "sha256-YlRKqa2XB7vFFZhrkIxTIA8zodZ5UpgAj6awDqF5Hy4=";
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
