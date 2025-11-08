{ pkgs ? import <nixpkgs> { }
,
}:

# Fetch MCP Server package (using Docker)
pkgs.writeShellScriptBin "rs-mcp-fetch" ''
  ${pkgs.docker}/bin/docker run -i --rm \
    -e NODE_OPTIONS="--no-warnings" \
    -e MCP_TRANSPORT_TYPE="stdio" \
    -e MCP_LOG_LEVEL="info" \
    mcp/fetch "$@"
''

