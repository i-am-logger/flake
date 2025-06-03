{
  pkgs ? import <nixpkgs> { },
}:

# Time MCP Server package
pkgs.writeShellScriptBin "rs-mcp-time" ''
  ${pkgs.docker}/bin/docker run -i --rm \
    -v /etc/localtime:/etc/localtime:ro \
    mcp/time \
    --local-timezone "$(${pkgs.systemd}/bin/timedatectl show --property=Timezone --value)" "$@"
''
