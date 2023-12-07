{ pkgs, config, ... }:

{

  environment.systemPackages = with pkgs; [
    pure-ftpd
    inetutils
  ];
  nixpkgs.config.packageOverrides = pkgs:
    {
      pure-ftpd = pkgs.pure-ftpd.overrideAttrs (oldAttrs: {
        configureFlags = oldAttrs.configureFlags ++ [ "--with-puredb" ];
      });
    };

  systemd.services.pure-ftpd = {
    description = "PureFTPD Server";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.pure-ftpd}/bin/pure-ftpd --noanonymous --notruncate --prohibitdotfilesread --maxdiskusagepct 90% --bind 2121 --chrooteveryone --nochmod --customerproof --dontresolve --passiveportrange 30000:30200";
    };
    environment = {
      PURE_PASSWDFILE = "/data/ftp/pure-ftpd.passwd";
      PURE_DBFILE = "/data/ftp/pure-ftpd.pdb";
    };
  };

  users.groups.ftp.gid = config.ids.gids.ftp;
  users.users.ftp = {
    uid = config.ids.uids.ftp;
    group = "ftp";
    description = "FTP user";
    home = "/data/ftp/";
  };

  networking.firewall.allowedTCPPortRanges = [{ from = 30000; to = 30200; }];
  networking.firewall.allowedTCPPorts = [ 2121 ];
}
