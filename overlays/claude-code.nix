# Override claude-code to v2.1.45
# Auto-updated by scripts/update-claude-code.sh
final: prev:
let
  version = "2.1.45";
  lockfile = ./claude-code-package-lock.json;
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-EWpGw/5rX4NBPx4sGnz3uzvUtSQKBzCBZPSCTYarsPI=";
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
      outputHash = "sha256-iIr1Qs2Hj5cQ97keUgjpxSUEriibX9TIGes0nMiHvvM=";
    };
  });
}
