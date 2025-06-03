{ pkgs ? import <nixpkgs> { } }:

# Playwright MCP Server package using Docker
pkgs.writeShellScriptBin "rs-mcp-playwright" ''
  ${pkgs.docker}/bin/docker run -i --rm \
    -e NODE_OPTIONS="--no-warnings" \
    -e MCP_TRANSPORT_TYPE="stdio" \
    -e MCP_LOG_LEVEL="info" \
    -e PLAYWRIGHT_BROWSERS_PATH=/ms-playwright \
    mcp/playwright "$@"
''

