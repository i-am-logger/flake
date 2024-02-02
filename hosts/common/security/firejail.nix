# https://nixos.wiki/wiki/Firejail
{ ... }: {
  programs.firejail = {
    enable = true;
  };
}
