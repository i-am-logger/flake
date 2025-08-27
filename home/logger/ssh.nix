{ ... }:
{
  # Ensure SSH is managed and set up connection multiplexing to cache the
  # authentication channel, so subsequent git pulls within the persist window
  # won't require another YubiKey touch.
  programs.ssh = {
    enable = true;
  };

  home.file.".ssh/config".text = ''
    Host github.com gitlab.com bitbucket.org
      User git
      # Allow gpg-agent provided keys (YubiKey OpenPGP) to be used by SSH
      IdentitiesOnly no
      # Point SSH to the agent socket exposed by gpg-agent (exported in env)
      IdentityAgent $SSH_AUTH_SOCK
      ControlMaster auto
      ControlPersist 1m
      ControlPath ~/.ssh/cm-%r@%h:%p
      ServerAliveInterval 60
      ServerAliveCountMax 3
  '';
}

