# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ lib, ... }: {
  # TODO: hostname should be a parameter
  networking.hostName = "handlink"; # Define your hostname.
  networking.wireless.enable = false; # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # temp fix for network
  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;
  # Enable networking
  networking.networkmanager.enable = true;
  networking.interfaces.enp118s0.useDHCP = true;
  networking.interfaces.br0.useDHCP = true;
  networking.bridges = {
    "br0" = {
      interfaces = [ "enp118s0" ];
    };
  };
  networking.enableIPv6 = false;
  # networking.dhcpcd.extraConfig = ''
  #   interface br0
  #   dhcp
  #   # dhcp6
  #   ipv4
  #   # ipv6

  # '';
  # networking.defaultGateway.interface = "enp118s0";
  # networking.defaultGateway.address = "192.168.0.1";
  # networking.useDHCP = lib.mkForce true;
  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 45563 ]; # #TODO - move to OBS config 45563 - obs-teleport
  # networking.firewall.allowedUDPPorts = [
  # 54186
  # ];
  # networking.firewall.allowedUDPPortRanges = [
  #   {
  #     from = 1;
  #     to = 1024;
  #   }
  # ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
}


