{ pkgs ? import <nixpkgs> { } }:

# GitHub MCP Server package (using Docker and gh auth token)
pkgs.writeShellScriptBin "github-mcp" ''
  ${pkgs.docker}/bin/docker run -i --rm \
    -e GITHUB_PERSONAL_ACCESS_TOKEN=$(${pkgs.gh}/bin/gh auth token) \
    -e GITHUB_TOOLSETS="repos,issues,pull_requests,code_security" \
    ghcr.io/github/github-mcp-server \
    ./github-mcp-server stdio "$@"
''

