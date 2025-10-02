{
  pkgs ? import <nixpkgs> { },
}:

{
  # rs-mcp-filesystem = pkgs.callPackage ./filesystem.nix { };
  # rs-mcp-git = pkgs.callPackage ./git.nix { };
  # rs-mcp-gitingest = pkgs.callPackage ./gitingest.nix { };
  # rs-mcp-github = pkgs.callPackage ./github.nix { };
  mcp-github = pkgs.callPackage ./github-mcp-server.nix { };
  # rs-mcp-chat = pkgs.callPackage ./chat.nix { };
  # rs-mcp-pulumi = pkgs.callPackage ./pulumi.nix { };
  # rs-mcp-fetch = pkgs.callPackage ./fetch.nix { };
  # rs-mcp-playwright = pkgs.callPackage ./playwright.nix { };
  # rs-mcp-time = pkgs.callPackage ./time.nix { };
  # rs-mcp-sequentialthinking = pkgs.callPackage ./sequentialthinking.nix { };
  # rs-mcp-context7 = pkgs.callPackage ./context7.nix { };
  # rs-mcp-youtube-transcript = pkgs.callPackage ./youtube-transcript.nix { };
}
