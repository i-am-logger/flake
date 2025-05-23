{
  pkgs ? import <nixpkgs> { },
}:

{
  rs-mcp-filesystem = pkgs.callPackage ./filesystem.nix { };
  rs-mcp-git = pkgs.callPackage ./git.nix { };
  rs-mcp-gitingest = pkgs.callPackage ./gitingest.nix { };
  rs-mcp-github = pkgs.callPackage ./github.nix { };
}
