{ config, pkgs, ... }:
{
  # YubiKey-related packages
  home.packages = with pkgs; [
    gnupg
    paperkey
    pcsclite
  ];

  home.sessionVariables = {
    SSH_AUTH_SOCK = "$(gpgconf --list-dirs agent-ssh-socket)";
    GPG_TTY = "$(tty)";
  };

  # Add a shell initialization hook
  programs.bash.initExtra = ''
    gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
  '';
  # Or for Zsh
  programs.zsh.initExtra = ''
    gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
  '';

  # GPG configuration
  programs.gpg = {
    enable = true;
    scdaemonSettings = {
      reader-port = "Yubikey";
      disable-ccid = true;
      card-timeout = "5";
    };
    settings = {
      no-greeting = true;
      no-emit-version = true;
      keyid-format = "0xlong";
      with-fingerprint = true;
      list-options = "show-uid-validity";
      verify-options = "show-uid-validity";
      use-agent = true;
      trust-model = "tofu+pgp";
      default-key = "3842FC405341B51B";
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
}
