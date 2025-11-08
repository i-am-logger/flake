{ pkgs ? import <nixpkgs> { }
,
}:

# GitHub MCP Server package (from github.com/mcp/github/github-mcp-server)
pkgs.writeShellScriptBin "mcp-github" ''
  set -e
  export NODE_OPTIONS="--no-warnings"
  export MCP_TRANSPORT_TYPE="stdio"
  export MCP_LOG_LEVEL="info"
  export PATH="${pkgs.github-mcp-server}/bin:${pkgs.git}/bin:${pkgs.gh}/bin:$PATH"

  # Use GitHub personal access token from gh auth
  export GITHUB_PERSONAL_ACCESS_TOKEN=$(${pkgs.gh}/bin/gh auth token 2>/dev/null || echo "")

  if [ -z "$GITHUB_PERSONAL_ACCESS_TOKEN" ]; then
    echo "Warning: No GitHub token found. Please run 'gh auth login' first."
    echo "Some functionality may be limited without authentication."
  fi

  # Run the Nix-installed github-mcp-server
  ${pkgs.github-mcp-server}/bin/github-mcp-server "$@" || {
    echo "Error: Failed to run github-mcp-server"
    echo "Please check your GitHub authentication and network connection"
    exit 1
  }
''
