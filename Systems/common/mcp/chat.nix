{
  pkgs ? import <nixpkgs> { },
}:

# GitHub Chat MCP Server package (using Docker and gh auth token)
pkgs.writeShellScriptBin "rs-mcp-chat" ''
  ${pkgs.docker}/bin/docker run -i --rm \
    -e GITHUB_PERSONAL_ACCESS_TOKEN=$(${pkgs.gh}/bin/gh auth token) \
    mcp/github-chat \
    stdio "$@"
''

