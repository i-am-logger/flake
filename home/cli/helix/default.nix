{ pkgs, ... }: {
  home.packages = [
    pkgs.helix
    pkgs.alejandra

    pkgs.nodePackages.bash-language-server
    pkgs.cmake-language-server

    pkgs.zellij
    pkgs.lazygit
    pkgs.nil
    pkgs.rnix-lsp
    pkgs.rust-analyzer
    pkgs.clang-tools
    pkgs.ocamlPackages.ocaml-lsp
    pkgs.vscode-langservers-extracted
    pkgs.dockerfile-language-server-nodejs
    pkgs.haskellPackages.haskell-language-server
    pkgs.nodePackages.typescript-language-server
    pkgs.texlab
    pkgs.lua-language-server
    pkgs.marksman
    pkgs.python310Packages.python-lsp-server
    pkgs.nodePackages.vue-language-server
    pkgs.yaml-language-server
    pkgs.taplo

    pkgs.tree-sitter
    (pkgs.tree-sitter.withPlugins (_: pkgs.tree-sitter.allGrammars))
    pkgs.nixpkgs-fmt
  ];

  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      editor = {
        line-number = "relative";
        bufferline = "multiple";
        mouse = true;
        true-color = true;
        color-modes = true;
        cursorline = true;
        auto-completion = true;
        completion-trigger-len = 1;

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        file-picker = {
          hidden = false;
          git-ignore = true;
        };
        soft-wrap = {
          enable = true;
        };
        statusline = {
          left = [ "mode" "spinner" ];
          center = [ "file-name" "position-percentage" ];
          right = [ "version-control" "diagnostics" "selections" "position" "file-encoding" "file-line-ending" "file-type" ];
          separator = "│";
        };
        lsp = {
          enable = true;
          display-messages = true;
          auto-signature-help = true;
          display-inlay-hints = true;
          display-signature-help-docs = true;
          snippets = true;
          goto-reference-include-declaration = true;
        };
        whitespace = {
          render = "all";
          characters = {
            space = " ";
            nbsp = "⍽";
            tab = "→";
            newline = "⏎";

            tabpad = "·"; # Tabs will look like "→···" (depending on tab width)
          };
        };
        indent-guides = {
          render = true;
          character = "╎";
        };
      };
      keys.normal = {
        esc = [ "collapse_selection" "keep_primary_selection" ];
        J = [ "delete_selection" "paste_after" ];
        K = [ "delete_selection" "move_line_up" "paste_before" ];
        C-u = [ "half_page_up" "align_view_center" ];
        C-d = [ "half_page_down" "align_view_center" ];

        "[" = "goto_previous_buffer";
        "]" = "goto_next_buffer";

        g = {
          x = ":buffer-close";
          j = "jump_backward";
          k = "jump_forward";
        };
        space = {
          l = ":toggle lsp.display-inlay-hints";
          n = ":toggle lsp.auto-signature_help";
        };

        backspace = {
          b = {
            r = ":run-shell-command zellij run -fc -- cargo build";
            n = ":run-shell-command zellij run -f -- nix build";
          };

          d = {
            d = ":run-shell-command zellij run -fc -- watch --color -n 0.2 lsd /dev/ttyACM* -h --color always";
            b = ":run-shell-command zellij run -fc -- btop";
          };

          r = {
            n = ":run-shell-command zellij run -f -- nix run";
            r = ":run-shell-command zellij run -fc -- cargo run";
          };

          t = {
            n = ":run-shell-command zellij run -f -- nix test";
            r = ":run-shell-command zellij run -fc -- cargo test";
          };

          g = ":run-shell-command zellij run -fc -- lazygit";
          f = ":run-shell-command zellij run -fc -- broot";
        };
      };
    };
    languages = {
      language = [
        {
          name = "nix";
          auto-format = true;
          formatter = { command = "nixpkgs-fmt"; };
          # language-servers = {command = "nil";};
        }
        {
          name = "typescript";
          auto-format = true;
        }
        {
          name = "javascript";
          auto-format = true;
        }
      ];
    };
  };
}
