{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.stacks.desktop;
in
{
  options.stacks.desktop = {
    enable = mkEnableOption "desktop stack (warp + vscode + browser)";
    
    warp = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Warp terminal";
      };
      
      preview = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Warp terminal preview version";
      };
    };
    
    vscode.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable VSCode";
    };
    
    browser.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable browser configuration";
    };
  };

  imports = [
    ./audio-tools.nix
  ];

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.warp.enable (import ./warp-terminal.nix { inherit config lib pkgs; }))
    (mkIf cfg.warp.preview (import ./warp-terminal-preview.nix { inherit config lib pkgs; }))
    (mkIf cfg.vscode.enable (import ./vscode.nix { inherit config lib pkgs; }))
    (mkIf cfg.browser.enable (import ./browser.nix { inherit config lib pkgs; }))
  ]);
}
