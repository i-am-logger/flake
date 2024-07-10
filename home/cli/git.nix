{ config
, pkgs
, lib
, ...
}: {
  home.packages = with pkgs; [
    gitui
    gh
  ];
  programs.git = {
    enable = true;
    lfs.enable = true;

    package = pkgs.gitAndTools.gitFull;
    userName = "Logger";
    userEmail = "ido.samuelson@gmail.com";
    signing = {
      key = "6AACFE7CBA89F53A"; # gpg --list-secret-keys --keyid-format=long
      # signByDefault = true;
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
      init = {
        defaultBranch = "main";
      };
      url = {
        "git@github.com:" = {
          insteadOf = [
            "https://github.com/"
          ];
        };
      };
      core = {
        editor = "hx";
        autocrlf = "input";
      };
      diff.algorithm = "histogram";
    };
    # delta.enable = true;
    # diff-so-fancy.enable = true;

    ignores = [ "*.img" ".direnv" "result" ];

    # difftastic = {
    #   enable = true;
    #   background = "dark";
    #   display = "inline";
    # };

    # diff-so-fancy = {
    #   enable = true;

    # };


    delta = {
      enable = true;
      options = {
        decorations = {
          commit-decoration-style = "bold yellow box ul";
          file-decoration-style = "none";
          file-style = "bold yellow ul";
        };
        features = "decorations";
        whitespace-error-style = "22 reverse";
      };
    };
  };

  programs.gitui.enable = true;

}
