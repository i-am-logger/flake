{ pkgs, python3 }:

let
  grok = pkgs.python3.pkgs.buildPythonPackage rec {
    pname = "grok";
    version = "0.1";

    src = pkgs.fetchFromGitHub {
      owner = "grok-ai";
      repo = "grok";
      rev = "v${version}";
      sha256 = "0000000000000000000000000000000000000000000000000000";
    };

    propagatedBuildInputs = with pkgs.python3.pkgs; [
      click
      requests
    ];

    doCheck = false; # No tests available

    meta = with pkgs.lib; {
      description = "Grok CLI tool";
      homepage = "https://github.com/grok-ai/grok";
      license = licenses.mit;
      platforms = platforms.unix;
      maintainers = with maintainers; [ realsnick ];
    };
  };
in
grok
