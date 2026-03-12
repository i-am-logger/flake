# Override claude-code to v2.1.74
# Auto-updated by scripts/update-claude-code.sh
final: prev:
let
  version = "2.1.74";
  lockfile = ./claude-code-package-lock.json;
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-74xAW5sc3l5SH7UUFsUVpK6A6gTPn4fGg+c51MsXXhE=";
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
      outputHash = "sha256-FQEQQK8UIvPw8WMYGW+X7TPAWi+SVJEhUV0MqO2gQz0=";
    };
  });
}
