{ pkgs, ... }: {
  services.emacs.enable = true;

  home.packages = with pkgs; [
    ripgrep
  ];


  programs.doom-emacs = {
    enable = true;
    doomPrivateDir = ./doom.d;
    # emacsPackage = pkgs.emacs29-pgtk;
  };
}
