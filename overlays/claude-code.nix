# Override claude-code to v2.1.105
# Auto-updated by scripts/update-claude-code.sh
final: prev:
let
  version = "2.1.105";
  lockfile = ./claude-code-package-lock.json;
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-IauZBWRzeatROeGOJI57fcD4Iz7NnmAtORf3lzaoOm4=";
  };
in
{
  claude-code = prev.claude-code.overrideAttrs (old: {
    inherit version src;
    postPatch = ''
      cp ${lockfile} package-lock.json

      substituteInPlace cli.js \
            --replace-fail '#!/bin/sh' '#!/usr/bin/env sh'
    '';
    npmDeps = old.npmDeps.overrideAttrs {
      inherit src;
      postPatch = ''
        cp ${lockfile} package-lock.json
      '';
      outputHash = "sha256-2cPwa+aRvbITthxWlhk+XLPRnBMCNOpY6+dagxZpTlY=";
    };
  });
}
