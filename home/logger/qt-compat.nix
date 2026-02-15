{ lib, ... }:

{
  # Compatibility module to add qt5ctSettings/qt6ctSettings options
  # that Stylix expects but aren't in this home-manager version
  options.qt = {
    qt5ctSettings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Dummy option for Stylix compatibility";
    };
    qt6ctSettings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Dummy option for Stylix compatibility";
    };
  };
}
