# Override opencode to v1.1.25
# nixpkgs has v1.1.23, we need the latest version
final: prev:
let
  version = "1.1.25";
  src = prev.fetchFromGitHub {
    owner = "anomalyco";
    repo = "opencode";
    tag = "v${version}";
    hash = "sha256-aF+4LL0x9wU2Ktrv/nJE2VXgUeXFrwJ16pa1sGNhpi4=";
  };
in
{
  opencode = prev.opencode.overrideAttrs (old: {
    inherit version src;
    node_modules = old.node_modules.overrideAttrs {
      inherit version src;
      outputHash = "sha256-1mxHtlq18f2dIkOkdxdCPlX6M9I3bd1DA8JCB4blqZE=";
    };
  });
}
