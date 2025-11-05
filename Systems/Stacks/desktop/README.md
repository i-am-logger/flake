# Development Environment SubSystem

Curated development tooling bundle for productive coding environments.

## Components

### Warp Terminal
- Modern terminal with AI features
- Support for both stable and preview versions
- Custom configurations

### VSCode
- IDE with extensions
- Custom settings
- Language support

### Browser
- Development-optimized browser configuration
- Extensions and profiles

## Configuration

```nix
{
  imports = [ ./Systems/SubSystems/development-environment ];
  
  subsystems.development-environment = {
    enable = true;
    warp = {
      enable = true;
      preview = false;  # Use stable by default
    };
    vscode.enable = true;
    browser.enable = true;
  };
}
```

## Options

Each component can be individually enabled/disabled.

## Files

- `warp-terminal.nix`: Stable Warp terminal
- `warp-terminal-preview.nix`: Preview Warp terminal
- `vscode.nix`: VSCode configuration
- `browser.nix`: Browser setup
- `default.nix`: Main module with options
