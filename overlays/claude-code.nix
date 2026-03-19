# Override claude-code to v2.1.79
# Auto-updated by scripts/update-claude-code.sh
final: prev:
let
  version = "2.1.79";
  lockfile = ./claude-code-package-lock.json;
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-SwR+d1EY7U8RytYIj3jsynsm+pVqp2eL8jrDRXLJino=";
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
      outputHash = "sha256-mT71BkQgKGNLn0TSpe1yslqrWb8lnrILptldw3cRmNY=";
    };
  });
}
