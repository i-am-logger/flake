{pkgs, ...}: {
  services.emacs.enable = true;

  programs.doom-emacs = {
    enable = true;
    doomPrivateDir = ./doom.d;
    emacsPackage = pkgs.emacs29-pgtk;
    #   nixpkgs.overlays = [
    #     (final: prev: {
    #       doom-emacs = prev.doom-emacs.overrideAttrs (old: {
    #         inputs.doom-emacs.url = "github:doomemacs/doomemacs";
    #       });
    #     })
    #   ];
  };
}
