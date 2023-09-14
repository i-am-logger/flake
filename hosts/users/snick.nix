# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{pkgs, ...}: {
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.snick = {
    name = "snick";
    initialPassword = "";
    isNormalUser = true;
    description = "Ido Samuelson";
    extraGroups = ["networkmanager" "wheel" "video" "audio" "udev" "dialout"];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC9NjxnmOErORVKkP/PelRMI0olYVl1ZHLWTqZz9OpULYjQCCFRGiOk5BShOsX5uU9IPEE9FByM+wVkVP4MXkDxHkHFUnRvHpTAuRkoZ+e6eHTtaWxHs1WjdXXklsx8MPgldtqxb8O6FzNz6QnYDIZirmf5i668pJoJj2o1XYUYX+RB8HYt5I2SUWwZJo93d8FJI9+lff7B3f6UTd9Kf4kRbuhGCIDvfvhr1aOrO83pebiuNWpWVfhpk/Ql+w0NMjQ3Rv+0kvmm7D+1Z7D43elrdv4r7XLkRu3pdN5gUZGZGaNUZCllRgnrbulhw4dpUYGiQdpB/Dh13/DrIHUllIfxf6ftu26EhmzCXQU+4QgrGo3MI44/Rcory3WPD29b9kABo9T7tOiQoIH0cx0pv4foB9sL0fHhelTqf/23pUQFIgU45s9vDYQZ07hBGGPv/PIMOU8mku4gZjU6JbBRa+uuRyYOB9tBv4KcenwkEA2G/4/96zBS6Q5+60EUIXeuEjU= snick@snick-desktop"
    ];
  };
}
