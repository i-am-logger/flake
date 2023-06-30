# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ self, pkgs, inputs,... }:

{

  manual.manpages.enable = true;

  programs = {
    home-manager.enable = true;
    bash.enable = true;
  };
  
  home = {   
    username = "snick";
    homeDirectory = "/home/snick";
    stateVersion = "23.11";

  };
  #nixpkgs.allowUnfree = true;
    
  imports = [
    ./common.nix      
  ];
}
