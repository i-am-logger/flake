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
        st = "status";
        op = "operation log";
      };

      git = {
        # Git integration settings
        auto-local-branch = true;
        push-branch-prefix = "jj/";
        abandon-unreachable-commits = false;
        # minutes before auto-expiring abandoned commits
        abandoned-commit-expiration = 60 * 24 * 7; # 1 week
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
