{ pkgs ? import <nixpkgs> { }
,
}:

let
  python3 = pkgs.python312;
  pythonPackages = python3.pkgs;

  gitingestMcp = pythonPackages.buildPythonApplication {
    pname = "gitingest-mcp";
    version = "0.1.4";

    src = pkgs.fetchFromGitHub {
      owner = "narumiruna";
      repo = "gitingest-mcp";
      rev = "main";
      hash = "sha256-3bNBg5QaVdRJ/PfppMQRRN+3GYegE2WzMle+gT1/GA8=";
    };

    format = "pyproject";

    nativeBuildInputs = with pythonPackages; [
      pip
      setuptools
      wheel
      poetry-core
      hatchling
    ];

    propagatedBuildInputs = with pythonPackages; [
      pkgs.gitingest
      loguru
      (mcp.overridePythonAttrs (oldAttrs: {
        extras = [ "cli" ];
      }))
    ];
    postInstall = ''
      # Create a wrapper script that sets up the environment
      mkdir -p $out/bin
      mv $out/bin/gitingestmcp $out/bin/gitingestmcp-unwrapped
      cat > $out/bin/gitingestmcp <<EOF
      #!/usr/bin/env bash
      export PATH="${pkgs.gitingest}/bin:\$PATH"
      exec $out/bin/gitingestmcp-unwrapped "\$@"
      EOF
      chmod +x $out/bin/gitingestmcp
    '';

    meta = with pkgs.lib; {
      description = "GitIngest MCP Server";
      homepage = "https://github.com/narumiruna/gitingest-mcp";
      license = licenses.mit;
    };
  };

in
# GitIngest MCP Server package
pkgs.writeShellScriptBin "rs-mcp-gitingest" ''
  set -e
  echo "Starting MCP GitIngest server..."
  echo "Setting up environment variables..."
  export NODE_OPTIONS="--no-warnings"
  export MCP_TRANSPORT_TYPE="stdio"
  export MCP_LOG_LEVEL="info"
  
  echo "Running gitingest-mcp with nixpkgs gitingest..."
  ${gitingestMcp}/bin/gitingestmcp "$@"
''
