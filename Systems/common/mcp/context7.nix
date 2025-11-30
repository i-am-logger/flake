{ pkgs ? import <nixpkgs> { } }:

let
  config = {
    mcpServers = {
      context7 = {
        command = "${pkgs.docker}/bin/docker";
        args = [
          "run"
          "-i"
          "--rm"
          "mcp/context7"
        ];
      };
    };
  };
in
pkgs.writeShellScriptBin "rs-mcp-context7" ''
  ${config.mcpServers.context7.command} ${builtins.toString config.mcpServers.context7.args} "$@"
''
