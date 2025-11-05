{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./cicd
    ./security
    ./desktop
    ./mcp-servers
  ];
}
