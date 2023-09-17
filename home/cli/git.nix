{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.git = {
    enable = true;
    package = pkgs.gitAndTools.gitFull;
    userName = "Sn|cK";
    userEmail = "ido.samuelson@gmail.com";
    signing = {
      key = "6AACFE7CBA89F53A"; # gpg --list-secret-keys --keyid-format=long
      signByDefault = true;
    };

    aliases = {
      ci = "commit";
      ca = "commit --amend";
      co = "checkout";
      s = "status";
      l = "log";
      graph = "log --decorate --oneline --graph";
    };
    extraConfig = {
      core = {
        editor = "hx";
        autocrlf = "input";
      };
      diff.algorithm = "histogram";
    };
    # delta.enable = true;
    # diff-so-fancy.enable = true;

    ignores = ["*.img" ".direnv" "result"];

    difftastic = {
      enable = true;
      background = "dark";
      display = "inline";
    };
  };
}
