{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.stacks.mcp-servers;
  
  # MCP Server packages
  mcp-packages = {
    # rs-mcp-filesystem = pkgs.callPackage ./servers/filesystem.nix { };
    # rs-mcp-git = pkgs.callPackage ./servers/git.nix { };
    # rs-mcp-gitingest = pkgs.callPackage ./servers/gitingest.nix { };
    # rs-mcp-github = pkgs.callPackage ./servers/github.nix { };
    mcp-github = pkgs.callPackage ./servers/github-mcp-server.nix { };
    # rs-mcp-chat = pkgs.callPackage ./servers/chat.nix { };
    # rs-mcp-pulumi = pkgs.callPackage ./servers/pulumi.nix { };
    # rs-mcp-fetch = pkgs.callPackage ./servers/fetch.nix { };
    # rs-mcp-playwright = pkgs.callPackage ./servers/playwright.nix { };
    # rs-mcp-time = pkgs.callPackage ./servers/time.nix { };
    # rs-mcp-sequentialthinking = pkgs.callPackage ./servers/sequentialthinking.nix { };
    # rs-mcp-context7 = pkgs.callPackage ./servers/context7.nix { };
    # rs-mcp-youtube-transcript = pkgs.callPackage ./servers/youtube-transcript.nix { };
  };
in
{
  options.stacks.mcp-servers = {
    enable = mkEnableOption "MCP servers stack";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = lib.attrValues mcp-packages;
  };
}
