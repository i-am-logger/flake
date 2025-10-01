{ pkgs, ... }:
let

  # Store the public key in the Nix store
  yubikey-pubkey = pkgs.writeTextFile {
    name = "yubikey_pubkey";
    text = builtins.readFile ./yubikey_pubkey.asc; # Assuming the file is in your config directory
    destination = "/yubikey_pubkey.asc";
  };

  gpg-import-yubikey = pkgs.writeShellScriptBin "gpg-import-yubikey" ''
    #!/usr/bin/env bash
    echo "Importing YubiKey public key..."
    gpg --import ${yubikey-pubkey}/yubikey_pubkey.asc

    echo "Setting trust level to ultimate..."
    echo -e "trust\n5\ny\nsave" | gpg --command-fd 0 --edit-key 3842FC405341B51B

    echo "YubiKey public key import complete"
  '';
in
{

  home.packages = [
    gpg-import-yubikey
  ];

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

    # Keep your existing settings
    settings = {
      # card-status-url = "https://keys.openpgp.org/vks/v1/by-fingerprint/B2678F2F11889414D65E9D463842FC405341B51B";
      trust-model = "tofu+pgp";
      use-agent = true;
      verify-options = "show-uid-validity";
      with-fingerprint = true;
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
    pinentry.package = pkgs.pinentry-gnome3;
    enableExtraSocket = true;
    enableScDaemon = true; # Explicitly enable scdaemon
    
    # Disable caching - require YubiKey touch for every operation
    defaultCacheTtl = 0;
    maxCacheTtl = 0;
    defaultCacheTtlSsh = 0;
    maxCacheTtlSsh = 0;
  };

  # Ensure the OpenPGP authentication subkey is authorized for SSH via gpg-agent
  # Keygrip for auth subkey (from gpg --list-secret-keys --with-keygrip):
  home.file.".gnupg/sshcontrol" = {
    text = ''
E546B8F9F3944F6E4C155CC4A403A3427EEFC78E
'';
    # Make sure directory exists with safe perms
    force = true;
  };

  # Git configuration for GPG signing
  programs.git = {
    userName = "Logger";
    userEmail = "i-am-logger@users.noreply.github.com";
    signing = {
      format = "openpgp";
      signByDefault = true;
      key = "3842FC405341B51B";
    };
    extraConfig = {
      gpg = {
        program = "${pkgs.gnupg}/bin/gpg";
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
        behavior = "own";  # Updated from deprecated sign-all = true
        backend = "gpg";
        key = "3842FC405341B51B";
      };
    };
  };
}
