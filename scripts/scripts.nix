{ writeShellScriptBin, ... }: {
  hi = writeShellScriptBin "hi" ''
    echo "hello"
  '';

  nixpkgs-review-pr = writeShellScriptBin "nixpkgs-review-pr" ''
    #!/usr/bin/env bash
    if [ -z "$1" ]; then
      echo "Usage: nixpkgs-review-pr PR_NUMBER"
      exit 1
    fi
    cd /home/logger/GitHub/logger/nixpkgs || exit 1
    nix-shell -p nixpkgs-review --run "nixpkgs-review pr $1 --no-shell"
  '';
}

