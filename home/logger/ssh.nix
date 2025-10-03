{ ... }:
{
  # Ensure SSH is managed and set up connection multiplexing to cache the
  # authentication channel, so subsequent git pulls within the persist window
  # won't require another YubiKey touch.
  programs.ssh = {
    enable = true;
  };

  home.file.".ssh/config".text = ''
    # Prefer FIDO2 (sk) key for GitHub to avoid GPG smartcard dependency
    Host github.com
      User git
      IdentitiesOnly yes
      IdentityAgent none
      IdentityFile ~/.ssh/id_ed25519_sk_github
      PubkeyAcceptedAlgorithms sk-ssh-ed25519@openssh.com
      HostkeyAlgorithms ssh-ed25519
      ControlMaster auto
      ControlPersist 1m
      ControlPath ~/.ssh/cm-%r@%h:%p
      ServerAliveInterval 60
      ServerAliveCountMax 3

    # Other forges can continue to use the agent-provided keys
    Host gitlab.com bitbucket.org
      User git
      IdentitiesOnly no
      IdentityAgent $SSH_AUTH_SOCK
      ControlMaster auto
      ControlPersist 1m
      ControlPath ~/.ssh/cm-%r@%h:%p
      ServerAliveInterval 60
      ServerAliveCountMax 3
  '';
}

