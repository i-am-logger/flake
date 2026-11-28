# Nix's trust on every NixOS host (security finding S2a; owner, 2026-11-28):
# Nix trusts root only. A trusted user is root-equivalent (nix.conf(5)), and
# @wheel included the owner's account, so every session running as it.
# Binary caches stay system-wide, where mynixos already lists devenv's
# (extra-substituters, with its key), so no trusted user is needed for them.
{ lib, ... }:
{
  nix.settings.trusted-users = lib.mkForce [ "root" ];
}
