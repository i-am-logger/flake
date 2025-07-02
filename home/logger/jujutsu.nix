{
  pkgs,
  ...
}:

{
  # Install the jujutsu package
  home.packages = [ pkgs.jujutsu ];

  # Configure jujutsu using Home Manager
  programs.jujutsu = {
    enable = true;

    settings = {
      user = {
        name = "Logger";
        email = "i-am-logger@users.noreply.github.com";
      };

      ui = {
        default-command = "status";
        paginate = "auto";
        color = "auto";
        diff-editor = "diff";
        merge-editor = "merge";
      };

      templates = {
        git-export-description = "git export: {description}";
        git-export-message = ''
          {description}

          JJ-ID: {short_id}
        '';
      };

      revsets = {
        # You can define aliases for commonly used revsets
        trunk = "remote_branches(origin/main)";
        recent = "mine() & (trunk.. | @)";
      };

      aliases = {
        # Custom command aliases
        l = "log -p";
        s = "status";
        co = "checkout";
        sw = "switch";
        b = "branch";
        c = "commit";
        a = "amend";
        # Removed st and op aliases as they override built-in commands
      };

      git = {
        # Git integration settings
        auto-local-bookmark = true;  # Renamed from auto-local-branch
        push-branch-prefix = "jj/";
        abandon-unreachable-commits = false;
        # minutes before auto-expiring abandoned commits
        abandoned-commit-expiration = 60 * 24 * 7; # 1 week
      };

      signing = {
        # Updated from deprecated signing.sign-all
        behavior = "own";
      };

      # Define operation hooks if needed
      operation.hooks = {
        post-commit = [ ];
        post-rebase = [ ];
      };
    };

    # Extra configuration through direct config file entries
    # extraConfig = ''
    #   [feature]
    #   # Enable experimental features
    #   # cli-inputs = false
    #   # conflict-detector = "disabled"
    # '';
  };
}
