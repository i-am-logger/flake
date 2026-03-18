# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').
{ pkgs, ... }:
{
  imports = [
    common/console.nix

    common/system.nix
    common/security/security.nix
    common/security/1password.nix
    common/security/yubikey-gpg.nix
    common/nix.nix
    common/nvidia.nix
    common/bluetooth.nix
    common/sound.nix
    common/electron-apps.nix

    common/environment.nix
    common/hyprland.nix
    common/niri.nix
    common/binfmt.nix
    common/appimage.nix
    common/direnv.nix
    common/xdg.nix
    common/v4l2loopback.nix
    common/docker.nix
    common/streamdeck.nix
    common/systemd-fixes.nix
    common/pam-fixes.nix
    common/plymouth.nix # Boot splash screen with NixOS logo
    common/systemd-boot.nix # Enhanced boot menu styling
    common/ollama.nix
    common/openclaw.nix
    users/logger.nix
  ];

  # Ollama: GPU auto-detected from nvidia.nix, just set models
  local.ollama.models = [ "qwen2.5:14b" ];

  # OpenClaw: gateway with Ollama as LLM provider
  local.openclaw = {
    enable = true;
    ollamaModel = "qwen2.5:14b";
  };

  services.usbmuxd.enable = true;

  # services.openssh.enable = true;

  services.fwupd.enable = true; # firmware update
  services.trezord.enable = true;
  # security.pam.services.swaylock = { };
  # XDG portal is configured in common/xdg.nix
}
