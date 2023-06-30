{ config, pkgs, lib, ... }: {
  programs.git = {
    enable = true;
    userName = "Sn|cK";
    userEmail = "ibootstrapper@gmail.com";
#    signing = {
#      key = ""; # gpg --list-secret-keys --keyid-format=long
#      signByDefault = true;
#    };
#    includes = [{
#      condition = "gitdir:~/dotfiles/git/conditions/";
#      path = "~/dotfiles/git/.gitconfig";
#    }];
    extraConfig = {
      core = {
        editor = "hx";
        autocrlf = "input";
      };
      diff.algorithm = "histogram";
    };
    delta.enable = true;
  };
}
