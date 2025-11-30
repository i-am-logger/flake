{ pkgs
, config
, ...
}:
{
  environment.systemPackages = with pkgs; [ nextcloud-client ];
  environment.etc."nextcloud-admin-pass".text = "1Q2w3e$R%T";
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud28;
    hostName = "localhost";
    # datadir = "/etc/snick-nextcloud";
    # database.createLocally = true;
    config = {
      adminuser = "admin";
      adminpassFile = "/etc/nextcloud-admin-pass";
    };

    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps) contacts calendar tasks;
    };
    extraAppsEnable = true;
  };
}
