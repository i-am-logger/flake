{ config, lib, pkgs, ... }:
{
  boot = {
    bootspec.enable = true;
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
      settings = {
        kernelSigningKeyPath = "/var/lib/sbctl/keys/db/db.key";
        kernelSigningCertPath = "/var/lib/sbctl/keys/db/db.pem";
        signByDefault = true;
      };
    };
  };

  # Add persistence for secure boot keys
  environment.persistence."/persist".directories = [ "/var/lib/sbctl" ];

  # system.activationScripts.lanzaboote-sign = {
  #   deps = [ "specialfs" ];
  #   text = ''
  #     if [ -d /boot/EFI/nixos ]; then
  #       echo "Signing kernel and boot entries with sbctl..."
  #       ${pkgs.sbctl}/bin/sbctl sign --save /boot/EFI/nixos/kernel-*.efi
  #       ${pkgs.sbctl}/bin/sbctl verify
  #     fi
  #   '';
  # };
}
