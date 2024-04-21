{ config, lib, ... }:
{
  #programs.rust-motd = {
  #  enable = true;
  #};
  users.motd = builtins.readFile ./motd.txt;
}