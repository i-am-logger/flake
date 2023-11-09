{ pkgs, ... }: {
  home.packages = with pkgs; [
    thefuck
    grc
    fzf
    fd
  ];

  programs.kitty.shellIntegration.enableFishIntegration = true;
  # programs.direnv.enableFishIntegration = true;
  services.gpg-agent.enableFishIntegration = true;

  programs.fish = {
    enable = true;

    shellAliases = {
      ".." = "cd ..";
      c = "clear";
      f = "free -h"; # memory usage
      # df = "df -h"; # disk usage
      g = "git";
      t = "tree -C";
      r = "ranger";
      h = "hx";
      et = "emacsclient -nw -c";
      e = "emacsclient -c";
    };

    interactiveShellInit = ''
      set fish_greeting # Disable greeting
    '';
    plugins = [
      # Enable a plugin (here grc for colorized command output) from nixpkgs
      {
        name = "tide";
        src = pkgs.fishPlugins.tide.src;
      }
      {
        name = "puffer";
        src = pkgs.fishPlugins.puffer.src;
      }
      {
        name = "fzf-fish";
        src = pkgs.fishPlugins.fzf-fish.src;
      }
      {
        name = "forgit";
        src = pkgs.fishPlugins.forgit.src;
      }
      {
        name = "foreign-env";
        src = pkgs.fishPlugins.foreign-env.src;
      }
      {
        name = "grc";
        src = pkgs.fishPlugins.grc.src;
      }
      {
        name = "colored-man-pages";
        src = pkgs.fishPlugins.colored-man-pages.src;
      }
      {
        name = "z";
        src = pkgs.fetchFromGitHub {
          owner = "jethrokuan";
          repo = "z";
          rev = "e0e1b9dfdba362f8ab1ae8c1afc7ccf62b89f7eb";
          sha256 = "0dbnir6jbwjpjalz14snzd3cgdysgcs3raznsijd6savad3qhijc";
        };
      }
    ];
  };
}
