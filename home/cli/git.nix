{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.git = {
    enable = true;
    userName = "Ido Samuelson";
    userEmail = "ido.samuelson@gmail.com";
    signing = {
      key = "6AACFE7CBA89F53A"; # gpg --list-secret-keys --keyid-format=long
      signByDefault = true;
    };
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
