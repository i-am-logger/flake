{ pkgs ? import <nixpkgs> { }
,
}:

# Filesystem MCP Server package (using official MCP server)
pkgs.writeShellScriptBin "rs-mcp-filesystem" ''
  export NODE_OPTIONS="--no-warnings"
  export PATH="${pkgs.nodePackages.npm}/bin:$PATH"
  npx -y @modelcontextprotocol/server-filesystem \
    "/tmp" \
    "/home/logger/Current-Rice/ukon" \
    "$@"
''
