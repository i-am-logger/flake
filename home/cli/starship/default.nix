{ ... }:
{
  home.packages = [

  ];

  programs.starship = {
    enable = true;
    settings = {
      "$schema" = "https://starship.rs/config-schema.json";
      format = "$shell $nix_shell$fill $direnv$pulumi$rust$nim$c$nodejs$golang$line_break$git_branch $git_commit $git_status $git_state$fill$username$hostname $battery $line_break$directory$fill$line_break$sudo$character";
      right_format = "";
      continuation_prompt = "[∙](bright-black) ";
      scan_timeout = 1;
      command_timeout = 500;
      add_newline = true;
      follow_symlinks = true;

      # Module configurations
      aws = {
        format = "on [$symbol($profile )(\\($region\\) )(\\[$duration\\] )]($style)";
        symbol = "☁️  ";
        style = "bold yellow";
        disabled = false;
        expiration_symbol = "X";
        force_display = false;
      };

      battery = {
        full_symbol = "";
        charging_symbol = "";
        discharging_symbol = "";
        unknown_symbol = "";
        empty_symbol = "";
        disabled = false;
        format = "[$symbol]($style)";
        display = [
          { threshold = 20; style = "red bold"; }
          { threshold = 40; style = "yellow"; }
          { threshold = 60; style = "purple"; }
          { threshold = 80; style = "blue"; }
          { threshold = 100; style = ""; }
        ];
      };

      character = {
        format = "$symbol";
        success_symbol = "[](bold green)";
        error_symbol = "[](bold red)";
        vimcmd_symbol = "[❮](bold green)";
        vimcmd_visual_symbol = "[❮](bold yellow)";
        vimcmd_replace_symbol = "[❮](bold purple)";
        vimcmd_replace_one_symbol = "[❮](bold purple)";
        disabled = false;
      };

      directory = {
        truncation_length = 3;
        truncate_to_repo = false;
        fish_style_pwd_dir_length = 3;
        use_logical_path = true;
        format = "[$read_only]($read_only_style)[$path]($style)";
        repo_root_format = "[$read_only]($read_only_style)[$before_root_path]($before_repo_root_style)[$repo_root]($repo_root_style)[$path]($style)";
        style = "white";
        repo_root_style = "underline cyan bold";
        disabled = false;
        read_only = "🔒";
        read_only_style = "red";
        truncation_symbol = "…/";
        home_symbol = " ~";
        use_os_path_sep = true;
      };

      git_branch = {
        format = "[$symbol$branch(:$remote_branch)]($style)";
        symbol = " ";
        style = "cyan bold";
        truncation_length = 9223372036854775807;
        truncation_symbol = "…";
        only_attached = false;
        always_show_remote = false;
        disabled = false;
      };

      git_commit = {
        commit_hash_length = 8;
        format = "\\($hash$tag\\)";
        style = "blue";
        only_detached = false;
        disabled = false;
        tag_symbol = " 🏷 ";
        tag_disabled = false;
        tag_max_candidates = 0;
      };

      git_status = {
        format = "([$ahead_behind$all_status]($style))";
        style = "";
        stashed = "[$\{count}](cyan) ";
        ahead = "[ ⇡$\{count}](purple) ";
        behind = "[ ⇣$\{count}](red) ";
        up_to_date = "[](green) ";
        diverged = "[ $\{count}](red) ";
        conflicted = "[ $\{count}](red) ";
        deleted = "[ $\{count}](green) ";
        renamed = "[ $\{count}](green) ";
        modified = "[ $\{count}](red) ";
        staged = "[ $\{count}](green) ";
        untracked = "[ $\{count}](red) ";
        disabled = false;
        ignore_submodules = false;
      };

      hostname = {
        ssh_only = true;
        ssh_symbol = " ";
        trim_at = ".";
        format = "[@$hostname$ssh_symbol]($style)";
        style = "bold yellow";
        disabled = false;
      };

      nix_shell = {
        format = "[$symbol$state]($style)";
        symbol = " ";
        style = "bold yellow";
        impure_msg = "impure!";
        pure_msg = "pure";
        unknown_msg = "unknown";
        disabled = false;
        heuristic = false;
      };

      nodejs = {
        format = " [$symbol]($style)";
        symbol = " ";
        style = "";
        disabled = false;
      };

      rust = {
        format = "[$symbol]($style)";
        symbol = " ";
        style = "";
        disabled = false;
      };

      fill = {
        symbol = " ";
        style = "black";
        disabled = false;
      };
    };
  };
}
