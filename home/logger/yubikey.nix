{ lib, pkgs, ... }:
let

  # Store both YubiKey public keys in the Nix store
  yubikey1-pubkey = pkgs.writeTextFile {
    name = "yubikey1_pubkey";
    text = builtins.readFile ./yubikey1_pubkey.asc;
    destination = "/yubikey1_pubkey.asc";
  };

  yubikey2-pubkey = pkgs.writeTextFile {
    name = "yubikey2_pubkey";
    text = builtins.readFile ./yubikey2_pubkey.asc;
    destination = "/yubikey2_pubkey.asc";
  };

  gpg-import-yubikey = pkgs.writeShellScriptBin "gpg-import-yubikey" ''
    #!/usr/bin/env bash
    echo "Importing both YubiKey public keys..."

    echo "Importing first YubiKey public key..."
    gpg --import ${yubikey1-pubkey}/yubikey1_pubkey.asc
    echo "Setting trust level to ultimate for first YubiKey..."
    echo -e "trust\n5\ny\nsave" | gpg --command-fd 0 --edit-key 42BF2C362C094388

    echo "Importing second YubiKey public key..."
    gpg --import ${yubikey2-pubkey}/yubikey2_pubkey.asc
    echo "Setting trust level to ultimate for second YubiKey..."
    echo -e "trust\n5\ny\nsave" | gpg --command-fd 0 --edit-key 9D92E6047DEB1589

    echo "Both YubiKey public keys imported and trusted!"
  '';
in
{

  home.packages = [
    gpg-import-yubikey
    # Password management with gopass
    pkgs.gopass
    pkgs.gopass-jsonapi # Browser integration for gopass
    pkgs.passExtensions.pass-import # Import from other password managers
    # Simple GPG wrapper that uses whichever YubiKey is available
    (pkgs.writeShellScriptBin "gpg-smart" ''
      #!/usr/bin/env bash

      # Detect which YubiKey is available and use the correct key
      if gpg --card-status 2>/dev/null | grep -q "17027658"; then
        # Second YubiKey is connected (current one)
        YUBIKEY_ID="9D92E6047DEB1589"
      elif gpg --card-status 2>/dev/null | grep -q "15147050"; then
        # First YubiKey is connected
        YUBIKEY_ID="42BF2C362C094388"
      else
        # No YubiKey detected, use default GPG behavior
        exec ${pkgs.gnupg}/bin/gpg "$@"
      fi

      # Replace any --local-user with email with our key ID
      args=()
      skip_next=false
      for arg in "$@"; do
        if [ "$skip_next" = true ]; then
          # Skip the email argument and replace with our key ID
          args+=("$YUBIKEY_ID")
          skip_next=false
          continue
        fi
        
        if [[ "$arg" == "--local-user" ]]; then
          args+=("$arg")
          skip_next=true
          continue
        elif [[ "$arg" == --local-user=* ]]; then
          # Replace the whole argument
          args+=("--local-user=$YUBIKEY_ID")
          continue
        elif [[ "$arg" == "-u" ]]; then
          args+=("$arg")
          skip_next=true
          continue
        elif [[ "$arg" =~ ^-.*u$ ]]; then
          # Handle combined arguments like -bsau
          # Keep all flags except 'u' and add separate --local-user
          other_flags="''${arg%u}"
          if [[ "$other_flags" != "-" ]]; then
            args+=("$other_flags")
          fi
          args+=("--local-user")
          skip_next=true
          continue
        fi
        
        args+=("$arg")
      done

      # If no --local-user was specified, add it
      if [[ "$*" != *"--local-user"* && "$*" != *"-u"* && "$*" != *u ]]; then
        args=("--local-user" "$YUBIKEY_ID" "''${args[@]}")
      fi

      exec ${pkgs.gnupg}/bin/gpg "''${args[@]}"
    '')
  ];

  # Automatically import YubiKey public keys on home-manager activation
  home.activation.importYubikeyKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo "Setting up YubiKey GPG keys..."

    # Delete any keys that are not our current YubiKeys
    for key_id in $(${pkgs.gnupg}/bin/gpg --list-keys --with-colons | grep ^pub | cut -d: -f5); do
      if [[ "$key_id" != "42BF2C362C094388" && "$key_id" != "9D92E6047DEB1589" ]]; then
        echo "Removing old key: $key_id"
        fingerprint=$(${pkgs.gnupg}/bin/gpg --list-keys --with-colons "$key_id" | grep ^fpr | cut -d: -f10 | head -1)
        ${pkgs.gnupg}/bin/gpg --batch --yes --delete-secret-and-public-keys "$fingerprint!" || true
      fi
    done

    # Import current YubiKey keys non-interactively
    ${pkgs.gnupg}/bin/gpg --batch --import ${yubikey1-pubkey}/yubikey1_pubkey.asc || true
    ${pkgs.gnupg}/bin/gpg --batch --import ${yubikey2-pubkey}/yubikey2_pubkey.asc || true

    # Set trust non-interactively (using fingerprints for reliability)
    echo "F8BEF681E3EE87A5DE4A9E7F42BF2C362C094388:6:" | ${pkgs.gnupg}/bin/gpg --import-ownertrust || true
    echo "3DAEA4C9D37037434CE604799D92E6047DEB1589:6:" | ${pkgs.gnupg}/bin/gpg --import-ownertrust || true

    echo "YubiKey GPG keyring cleaned and configured"
  '';

  # Add shell initialization hooks
  programs.bash.initExtra = ''
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
    export GPG_TTY=$(tty)
    # Disable GNOME Keyring SSH agent
    unset GNOME_KEYRING_CONTROL
    export DISABLE_GNOME_KEYRING=1
    gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1

    # Update GPG_TTY and notify gpg-agent before each command
    # This ensures pinentry dialogs work in GUI terminals like Warp
    _update_gpg_tty() {
      export GPG_TTY=$(tty)
      gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
    }
    PROMPT_COMMAND="_update_gpg_tty; ''${PROMPT_COMMAND}"
  '';

  # For Zsh
  programs.zsh.initExtra = ''
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
    export GPG_TTY=$(tty)
    # Disable GNOME Keyring SSH agent
    unset GNOME_KEYRING_CONTROL
    export DISABLE_GNOME_KEYRING=1
    gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
  '';

  # GPG configuration
  programs.gpg = {
    enable = true;

    # Configure GPG to automatically choose available YubiKey based on email
    settings = {
      trust-model = "tofu+pgp";
      use-agent = true;
      verify-options = "show-uid-validity";
      with-fingerprint = true;
      # Set multiple default keys - GPG will try them in order
      default-key = [
        "42BF2C362C094388" # YubiKey 1
        "9D92E6047DEB1589" # YubiKey 2
      ];
      default-recipient-self = true;
      auto-key-locate = "local";
      keyid-format = "long";
    };

    # Force scdaemon to use PC/SC for PIV/X.509 (disables native CCID)
    scdaemonSettings = {
      disable-ccid = true;
    };
  };

  # GPG agent configuration
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    # Use GNOME pinentry for manual PIN entry
    # NOTE: Cannot use gopass-based pinentry due to circular dependency:
    # pinentry needs gopass → gopass needs GPG → GPG needs pinentry → infinite loop
    extraConfig = ''
      pinentry-program /run/current-system/sw/bin/pinentry-gnome3
    '';
    enableExtraSocket = true;
    enableScDaemon = true; # Explicitly enable scdaemon

    # Disable caching - require YubiKey touch for every operation
    defaultCacheTtl = 0;
    maxCacheTtl = 0;
    defaultCacheTtlSsh = 0;
    maxCacheTtlSsh = 0;
  };

  # Ensure both YubiKey authentication subkeys are authorized for SSH via gpg-agent
  # Keygrips for auth subkeys from both YubiKeys (hardcoded for security)
  home.file.".gnupg/sshcontrol" = {
    text = ''
      # First YubiKey authentication keygrip (ED25519)
      504BF2F0CD516A5FD35A640B1719EA8CD73EF2DA
      # Second YubiKey authentication keygrip (ED25519) 
      90687F2920871E0132190BE0142A24C3D3A9090F
    '';
    force = true;
  };

  # Git configuration for GPG signing - use smart wrapper
  programs.git = {
    userName = "Logger";
    userEmail = "i-am-logger@users.noreply.github.com";
    signing = {
      format = "openpgp";
      signByDefault = true;
      # Use email - smart wrapper will choose the right key
      key = "i-am-logger@users.noreply.github.com";
    };
    extraConfig = {
      gpg = {
        # Use smart wrapper that detects available YubiKey
        program = "gpg-smart";
        openpgp = {
          program = "gpg-smart";
        };
      };
    };
  };

  programs.jujutsu = {
    settings = {
      user = {
        name = "Logger";
        email = "i-am-logger@users.noreply.github.com";
      };
      signing = {
        behavior = "own"; # Updated from deprecated sign-all = true
        backend = "gpg";
        # Let GPG choose key based on email
        key = "i-am-logger@users.noreply.github.com";
      };
    };
  };

  # Password store (pass) configuration
  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
    settings = {
      PASSWORD_STORE_DIR = "$HOME/.password-store";
      PASSWORD_STORE_CLIP_TIME = "45";
    };
  };

  # Initialize password store with both YubiKey GPG keys for redundancy
  # Newline-separated keys (standard format)
  home.file.".password-store/.gpg-id" = {
    text = ''
      42BF2C362C094388
      9D92E6047DEB1589
    '';
    force = true;
  };

  # Gopass configuration with auto-sync
  home.file.".config/gopass/config.yml" = {
    text = ''
      core:
        autopush: true
        autosync: true
        cliptimeout: 45
        exportkeys: true
        notifications: true
        follow-references: false
      pwgen:
        xkcd-lang: en
      mounts:
        path: /home/logger/.password-store
    '';
    force = true;
  };

  # Browser integration for pass
  programs.browserpass = {
    enable = true;
    browsers = [
      "firefox"
      "chrome"
      "chromium"
      "brave"
    ];
  };

  # Gopass browser integration for Brave (replicates gopass-jsonapi configure)
  home.file.".config/BraveSoftware/Brave-Browser/NativeMessagingHosts/com.justwatch.gopass.json" = {
    text = builtins.toJSON {
      name = "com.justwatch.gopass";
      description = "Gopass wrapper to search and return passwords";
      path = "/home/logger/.config/gopass/gopass_wrapper.sh";
      type = "stdio";
      allowed_origins = [
        "chrome-extension://kkhfnlkhiapbiehimabddjbimfaijdhk/" # Gopass Bridge extension ID
      ];
    };
    force = true;
  };

  # Create gopass wrapper script for browser integration (replicates gopass-jsonapi configure)
  home.file.".config/gopass/gopass_wrapper.sh" = {
    text = ''
      #!/bin/sh

      export PATH="$PATH:$HOME/.nix-profile/bin" # required for Nix
      export PATH="$PATH:/usr/local/bin" # required on MacOS/brew  
      export PATH="$PATH:/usr/local/MacGPG2/bin" # required on MacOS/GPGTools GPGSuite
      export GPG_TTY="$(tty)"

      # Uncomment to debug gopass-jsonapi
      # export GOPASS_DEBUG_LOG=/tmp/gopass-jsonapi.log

      if [ -f ~/.gpg-agent-info ] && [ -n "$(pgrep gpg-agent)" ]; then
        source ~/.gpg-agent-info
        export GPG_AGENT_INFO
      else
        eval $(gpg-agent --daemon)
      fi

      export PATH="$PATH:/usr/local/bin"

      ${pkgs.gopass-jsonapi}/bin/gopass-jsonapi listen

      exit $?
    '';
    executable = true;
    force = true;
  };
}
