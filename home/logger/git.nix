{ pkgs
, ...
}:
{
  home.packages = with pkgs; [
    # gitui
    gh
    lazygit
  ];

  # programs.gitui.enable = true;
  programs.git = {
    enable = true;
    lfs.enable = true;
    package = pkgs.gitAndTools.gitFull;

    aliases = {
      ci = "commit";
      ca = "commit --amend";
      co = "checkout";
      s = "status";
      l = "log --pretty=format:'%C(yellow)%h%Creset %C(cyan)%G?%Creset %C(white)%d%Creset %s %C(cyan)(%cr) %C(bold blue)<%an>%Creset'";
      graph = "log --decorate --oneline --graph";
      signature = "log --pretty=format:'⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯%n✧ %C(yellow)%h%Creset %(if:equals=G,%(G?))%C(green)✓%Creset%(else)%C(red)✉%Creset%(end) %C(white)%d%Creset %s%n⌘ %C(cyan)(%cr)%Creset %C(bold blue)<%an>%Creset%n⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯'";
    };

    extraConfig = {
      url = {
        "git@github.com:" = {
          insteadOf = [ "https://github.com/" ];
        };
      };
      core = {
        editor = "hx";
      };
    };

    ignores = [
      "*.img"
      ".direnv"
      "result"
    ];

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

}
