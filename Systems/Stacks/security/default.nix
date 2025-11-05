{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.stacks.security;
in
{
  imports = [
    # Always import lanzaboote module so it's available when needed
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  options.stacks.security = {
    enable = mkEnableOption "security stack (secure-boot + yubikey + audit)";
    
    secureBoot.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable secure boot with lanzaboote";
    };
    
    yubikey.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable YubiKey support";
    };
    
    auditRules.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable audit rules for root execve";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.secureBoot.enable {
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

      # Add sbctl for debugging and troubleshooting Secure Boot
      environment.systemPackages = with pkgs; [
        sbctl
      ];
    })
    (mkIf cfg.yubikey.enable (import ./yubikey.nix { inherit config lib pkgs; }))
    (mkIf cfg.auditRules.enable {
      security.auditd.enable = true;
      security.audit.enable = true;
      security.audit.rules = [
        "-a exit,always -F arch=b64 -F euid=0 -S execve"
        "-a exit,always -F arch=b32 -F euid=0 -S execve"
      ];
      
      security.sudo.extraConfig = ''
        Defaults timestamp_timeout=0
        Defaults !tty_tickets
        Defaults log_output
        Defaults log_input
        Defaults logfile=/var/log/sudo.log
      '';
    })
  ]);
}
