# Override claude-code to v2.1.59
# Auto-updated by scripts/update-claude-code.sh
final: prev:
let
  version = "2.1.59";
  lockfile = ./claude-code-package-lock.json;
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-Dam9aJ0qBdqU40ACfzGQHuytW6ur0fMLm8D5fIKd1TE=";
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
      outputHash = "sha256-K+8xoBc3apvxQ9hCpYywqgBcfLxMWSxacgJcMH8mK7E=";
    };
  });
}
