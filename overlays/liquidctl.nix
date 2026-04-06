final: prev: {
  liquidctl = prev.liquidctl.overridePythonAttrs (old: {
    src = final.fetchFromGitHub {
      owner = "i-am-logger";
      repo = "liquidctl";
      rev = "67c07ff";
      hash = "sha256-U22jjegukOUBsDNMXuUQeNLf3DDAtosGGFGc84royWU=";
    };
  });
}
