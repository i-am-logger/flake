# Security SubSystem

Comprehensive security configuration bundle for NixOS systems.

## Components

### Secure Boot
- Lanzaboote integration
- TPM support
- UEFI Secure Boot enforcement

### YubiKey
- GPG smart card support
- U2F authentication
- SSH key management

### Audit Rules
- Root execve monitoring
- Sudo logging
- Enhanced audit trail

## Configuration

```nix
{
  imports = [ ./Systems/SubSystems/security ];
  
  subsystems.security = {
    enable = true;
    secureBoot.enable = true;
    yubikey.enable = true;
    auditRules.enable = true;
  };
}
```

## Options

All components can be selectively enabled/disabled via options.

## Files

- `secure-boot.nix`: Lanzaboote secure boot configuration
- `yubikey.nix`: YubiKey hardware token support
- `default.nix`: Main module with options
