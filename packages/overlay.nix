self: super:
let
  cursorPackage = self.callPackage ../cursor.nix { };
in
{
  # Your existing overlays...
  cursor = builtins.trace "Defining cursor package" cursorPackage;
}
