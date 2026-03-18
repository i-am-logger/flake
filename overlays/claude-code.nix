# Override claude-code to v2.1.76
# Auto-updated by scripts/update-claude-code.sh
final: prev:
let
  version = "2.1.76";
  lockfile = ./claude-code-package-lock.json;
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-kjzPTG32f35eN6S85gGLUCmsNwH70Sq5rruEs/0hioM=";
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
      outputHash = "sha256-sk1RdPMgZD+Ejd6JdKWcK24AdfasnwWATQkwAx5MjmY=";
    };
  });
}
