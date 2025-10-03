{ pkgs, ... }:

{
  # Fix SSH and GPG agent environment variables
  # Set these at the session level to avoid PAM expandable variable issues
  environment.sessionVariables = {
    # Set SSH_AUTH_SOCK to use GPG agent if not already set
    SSH_AUTH_SOCK = "\${SSH_AUTH_SOCK:-$(gpgconf --list-dirs agent-ssh-socket)}";
  };

  # Enable GPG agent for SSH support
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
