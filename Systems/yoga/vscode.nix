{ pkgs, ... }:

{
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (pkg.pname or pkg.name) [
      "vscode"
      "vscode-with-extensions"
    ];

  environment.systemPackages = with pkgs; [
    vscode
    # (vscode-with-extensions.override {
    #   vscodeExtensions = [
    #     #   # Currently active extensions
    #     # ms-vscode-remote.remote-ssh # Remote SSH

    #     # # Nix development extensions
    #     # bbenoist.nix # Nix language support
    #     # jnoortheen.nix-ide # Nix IDE features
    #     # arrterian.nix-env-selector # Nix environment selector

    #     # #   # Additional extensions (commented out but can be enabled as needed)
    #     # #   # vscodevim.vim                        # Vim keybindings
    #     # #   # ms-vscode.cpptools                   # C/C++ support
    #     # #   # ms-python.python                     # Python support
    #     # rust-lang.rust-analyzer # Rust support
    #     # redhat.vscode-yaml # YAML support
    #     # eamodio.gitlens # Git integration
    #   ];
    #   # ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
    #   #   # Any additional marketplace extensions can be added here
    #   # ];
    # })

    # Add some common dependencies that might be needed by VS Code or its extensions
    # git # Required for source control features
    # gnupg  # Optional for GPG signing
    # unzip
    # xdg-utils
    libsecret # For keyring integration

    # Add wayland-specific dependencies
    libxkbcommon
    # pipewire # For screen sharing support
  ];

  # Configure environment variables for better Wayland support
  environment.sessionVariables = {
    # Enable Wayland support for Electron apps like VS Code
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
  };

  # Enable good font rendering for VS Code
  fonts.fontconfig.enable = true;

  xdg.mime.enable = true;
  xdg.icons.enable = true;

  # Enable D-Bus service
  services.dbus.enable = true;

  # Enable Wayland portals
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
  };
}
