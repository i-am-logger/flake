{
  pkgs ? import <nixpkgs> { },
}:

# YouTube transcripts MCP Server for retrieving video transcripts
pkgs.writeShellScriptBin "rs-mcp-youtube-transcript" ''
  ${pkgs.docker}/bin/docker run -i --rm \
    mcp/youtube-transcript \
    "$@"
''

