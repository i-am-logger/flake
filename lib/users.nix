{ ... }:

{
  logger = {
    name = "logger";
    nixosUser = ../hosts/users/logger.nix;
    homeManager = ../home/logger;
  };
  
  snick = {
    name = "snick";
    nixosUser = ../hosts/users/snick.nix;
    homeManager = ../home/snick.nix;
  };
}
