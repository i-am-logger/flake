{
  pkgs ? import <nixpkgs> { },
}:

# Git MCP Server package (by cyanheads)
pkgs.writeShellScriptBin "rs-mcp-git" ''
  set -e
  # echo "Starting MCP Git server (by cyanheads)..."
  # echo "Setting up environment variables..."
  export NODE_OPTIONS="--no-warnings"
  export MCP_TRANSPORT_TYPE="stdio"
  export MCP_LOG_LEVEL="info"
  export PATH="${pkgs.nodejs}/bin:${pkgs.nodePackages.npm}/bin:${pkgs.git}/bin:${pkgs.gh}/bin:$PATH"

  # echo "Node.js version: $(node --version)"
  # echo "NPM version: $(npm --version)"
  # echo "Git version: $(git --version)"

  # echo "Installing and running git-mcp-server from npm..."
  # echo "Note: Use git_set_working_dir tool to set the working directory"

  npx --debug -y @cyanheads/git-mcp-server "$@" || {
      echo "Error: Failed to run git-mcp-server"
      echo "Please check if the repository exists and is accessible"
      exit 1
    }
''
