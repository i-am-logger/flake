{ config, pkgs, ... }:
{
  # Git and related packages
  environment.systemPackages = with pkgs; [
    git
    git-lfs
    gh
    gitui
    lazygit
    delta  # For git diff highlighting
  ];

  # System-wide git configuration
  environment.etc."gitconfig".text = ''
    [user]
      name = logger
      email = i-am-logger@users.noreply.github.com
      signingkey = 6AACFE7CBA89F53A

    [commit]
      gpgsign = true

    [tag]
      gpgsign = true

    [gpg]
      program = ${pkgs.gnupg}/bin/gpg2

    [init]
      defaultBranch = main

    [url "git@github.com:"]
      insteadOf = https://github.com/

    [core]
      editor = hx
      autocrlf = input

    [diff]
      algorithm = histogram

    [alias]
      ci = commit
      ca = commit --amend
      co = checkout
      s = status
      l = log
      graph = log --decorate --oneline --graph

    [delta]
      features = decorations
      whitespace-error-style = 22 reverse

    [delta "decorations"]
      commit-decoration-style = bold yellow box ul
      file-decoration-style = none
      file-style = bold yellow ul
  '';
}

