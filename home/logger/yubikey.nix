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
    gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
  '';

  # For Zsh
  programs.zsh.initExtra = ''
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
    export GPG_TTY=$(tty)
    gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
  '';

  # GPG configuration
  programs.gpg = {
    enable = true;
    scdaemonSettings = {
      disable-ccid = false;
      card-timeout = "5";
      pcsc-driver = "${pkgs.pcsclite}/lib/libpcsclite.so";
    };

    # Keep your existing settings
    settings = {
      # card-status-url = "https://keys.openpgp.org/vks/v1/by-fingerprint/B2678F2F11889414D65E9D463842FC405341B51B";
      cert-digest-algo = "SHA512";
      charset = "utf-8";
      default-key = "3842FC405341B51B";
      default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
      fixed-list-mode = true;
      keyid-format = "0xlong";
      list-options = "show-uid-validity";
      no-comments = true;
      no-emit-version = true;
      no-greeting = true;
      no-symkey-cache = true;
      personal-cipher-preferences = "AES256 AES192 AES";
      personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
      personal-digest-preferences = "SHA512 SHA384 SHA256";
      require-cross-certification = true;
      s2k-cipher-algo = "AES256";
      s2k-digest-algo = "SHA512";
      trust-model = "tofu+pgp";
      use-agent = true;
      verify-options = "show-uid-validity";
      with-fingerprint = true;
    };
  };

  # GPG agent configuration
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    defaultCacheTtl = 600;
    maxCacheTtl = 7200;
    pinentryPackage = pkgs.pinentry-curses;
    enableExtraSocket = true;
  };

  # Add a script to help restore your public key if needed in the future
  home.file."gpg-restore-pubkey.sh" = {
    text = ''
      #!/usr/bin/env bash
      # Script to retrieve your public key from keys.openpgp.org
      gpg --keyserver hkps://keys.openpgp.org --recv-keys 3842FC405341B51B
      gpg --edit-key 3842FC405341B51B
      # Then manually enter 'trust', '5', 'y', 'save'
    '';
    executable = true;
  };

  # Git configuration for GPG signing
  programs.git = {
    userName = "Logger";
    userEmail = "i-am-logger@users.noreply.github.com";
    signing = {
      key = "3842FC405341B51B";
      format = "openpgp";
      signByDefault = true;
    };
    extraConfig = {
      gpg = {
        program = "${pkgs.gnupg}/bin/gpg";
      };
    };
  };
}
