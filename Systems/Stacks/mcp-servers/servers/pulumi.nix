{
  pkgs ? import <nixpkgs> { },
}:

# Pulumi MCP Server package (using Docker)
pkgs.writeShellScriptBin "rs-mcp-pulumi" ''
  ${pkgs.docker}/bin/docker run -i --rm \
    mcp/pulumi \
    stdio "$@"
''

