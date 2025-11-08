{ pkgs ? import <nixpkgs> { }
,
}:

# Sequential Thinking MCP Server package
pkgs.writeShellScriptBin "rs-mcp-sequentialthinking" ''
  ${pkgs.docker}/bin/docker run -i --rm \
    mcp/sequentialthinking \
    ./sequential-thinking-mcp-server stdio "$@"
''

