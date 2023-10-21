{pkgs, ...}: {
  # services.emacs.enable = true;
  programs.emacs = {
    enable = true;
    package = pkgs.emacs29-pgtk;

    extraPackages = epkgs:
      with epkgs; [
        nix-mode
        nix-ts-mode
        flycheck
        json-mode
        python-mode
        auto-complete
        web-mode
        smart-tabs-mode
        whitespace-cleanup-mode
        flycheck-pyflakes
        yarn-mode
        yaml-mode
        typescript-mode
        toml-mode

        todotxt-mode
        syslog-mode
        # strace-mode
        svg-tag-mode
        # svg-mode-line-themes
        # https://github.com/sabof/svg-mode-line-themes
        ssh-config-mode
        show-font-mode
        rust-mode
        remark-mode # remark - slides
        python-mode
        power-mode
        mode-line-debug
        mode-icons
        mermaid-mode
        graphql-mode
        # graphql-ts-mode
        flycheck-color-mode-line
        fish-mode
        fira-code-mode
        dotenv-mode
        dockerfile-mode
        docker-compose-mode
        cmake-mode
        celestial-mode-line
        cargo-mode
        # auto-sort-mode
        arduino-mode
        arduino-cli-mode
        annoying-arrows-mode
        fzf
        ssh
      ];

    extraConfig = ''
      (setq standard-indent 2)
    '';
  };
}
