# Override opencode to v1.2.6
# Auto-updated by scripts/update-opencode.sh
final: prev:
let
  version = "1.2.6";
  src = prev.fetchFromGitHub {
    owner = "anomalyco";
    repo = "opencode";
    tag = "v${version}";
    hash = "sha256-43vPMyO7DsAgKrh0Wmt7jLDYCWUsaj30nBITreyYgX8=";
  };
in
{
  opencode = prev.opencode.overrideAttrs (old: {
    inherit version src;
    node_modules = old.node_modules.overrideAttrs {
      inherit version src;
      outputHash = "sha256-9Lv2bS7tFIfDhDkoV2iZkkodvwqC9rnL+D+vC64TorA=";
    };
  });
}
