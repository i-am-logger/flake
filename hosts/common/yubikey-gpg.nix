{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    yubikey-personalization
    gnupg
    age
    yubikey-manager
    cryptsetup
  ];

  services.udev.packages = with pkgs; [
    yubikey-personalization
  ];

  programs.gnupg.agent = {
    enable = true;
    pinentryFlavor = "curses";
    enableSSHSupport = true;
  };
}
