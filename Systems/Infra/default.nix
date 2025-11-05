{ config, lib, pkgs, ... }:

{
  imports = [
    ./services
    ./apps
  ];
}
