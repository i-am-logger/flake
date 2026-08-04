# Per-user home-manager config for logger on aether5d-dev.
#
# Everything here is either (a) filling a gap mynixos does not cover yet, or
# (b) overriding a mynixos app module that hardcodes a Linux assumption.
# Phase 2 empties this file by pushing each item upstream.
{ pkgs, lib, ... }:

{
  home.stateVersion = "26.11";

  # The native claude-code installer lives here and is not managed by Nix
  # (see ./default.nix for why). Host-specific, so it stays out of mynixos.
  home.sessionPath = [ "$HOME/.local/bin" ];

  home.packages = [
    # Secure Enclave SSH agent. The key itself must be created in the app;
    # a Secure Enclave key cannot be provisioned declaratively.
    pkgs.secretive
  ];

  programs.starship.enableZshIntegration = true;
  programs.direnv.enableZshIntegration = true;

  # cava, cava-peaks and git all come from mynixos now — the tuned cava settings
  # and the cava-peaks package moved upstream into
  # my/users/apps/visualizers/cava, which picks portaudio + Background Music on
  # darwin and pipewire on Linux. Nothing to override here.

  # ---------------------------------------------------------------------------
  # SSH — Touch ID via Secretive's Secure Enclave agent.
  # ---------------------------------------------------------------------------
  # mynixos's apps/ssh module turns on gpg-agent SSH support for the YubiKey
  # flow on the Linux hosts. home-manager's services.gpg-agent emits no launchd
  # agents on darwin so it is already inert, but force it off so SSH_AUTH_SOCK
  # is unambiguous and the intent is legible.
  services.gpg-agent.enableSshSupport = lib.mkForce false;

  programs.ssh.settings."*".IdentityAgent =
    "~/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
}
