{
  pkgs ? import <nixpkgs> { },
}:

pkgs.python3Packages.buildPythonApplication rec {
  pname = "qspectrumanalyzer";
  version = "2.2.0";

  src = pkgs.fetchFromGitHub {
    owner = "xmikos";
    repo = "qspectrumanalyzer";
    rev = "v${version}";
    sha256 = "0vpi981m2xsmksxy2m08hpi5h3rayq3kaxlf8iry4r988p45lirs"; # Replace this with the actual SHA256 hash
  };

  propagatedBuildInputs = with pkgs.python3Packages; [
    pyqt6
    pyqtgraph
    soapy_power
  ];

  meta = with pkgs.lib; {
    description = "Spectrum analyzer for multiple SDR platforms";
    homepage = "https://github.com/xmikos/qspectrumanalyzer";
    license = licenses.gpl3;
    maintainers = with maintainers; [ i_am_logger ];
  };
}
