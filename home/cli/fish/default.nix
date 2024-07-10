{ pkgs, ... }: {
  home.packages = with pkgs; [
    # thefuck
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
      ff = "fd --type file --color always | fzf --ansi"; # find file
      ffd = "fd --type directory --color always | fzf --ansi"; # find file
      eff = "$EDITOR (ff)"; # edit find file
      cdf = "cd (ffd)"; # cd find dir
      cf = "find . -type f | wc -l"; #count files in dir recursivley

      f = "free -h"; # memory usage
      # df = "df -h"; # disk usage
      g = "git";
      t = "tree -Cd -L 2";
      # r = "ranger";
      y = "yazi";
      h = "hx";
      za = "zellij attach";
      zz = "zellij -l layout.kdl";
      et = "emacsclient -nw -c";
      e = "emacsclient -c";

      mnt = "mount | awk -F' ' '{ printf \"%s\t%s\n\",\$1,\$3; }' | column -t | egrep ^/dev/ | sort";
      cpv = "rsync - ah - -info=progress2";
      weather = "curl wttr.in";
    };

    interactiveShellInit = ''
      set fish_greeting # Disable greeting
      function cl --argument dir
        if [ "dir" = "" ]
          builtin cd $HOME
        else
          builtin cd $dir
        end
        ls -a 
      end
    '';

    plugins = [
      # Enable a plugin (here grc for colorized command output) from nixpkgs
      # {
      #   name = "tide";
      #   src = pkgs.fishPlugins.tide.src;
      # }
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






