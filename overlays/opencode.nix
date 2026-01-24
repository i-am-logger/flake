# Override opencode to v1.1.34
# Auto-updated by scripts/update-opencode.sh
final: prev:
let
  version = "1.1.34";
  src = prev.fetchFromGitHub {
    owner = "anomalyco";
    repo = "opencode";
    tag = "v${version}";
    hash = "sha256-ardM8zEJWvTvsFMQZWivjGPB2uIqFw6QPAzrRjAHQKY=";
  };
in
{
  opencode = prev.opencode.overrideAttrs (old: {
    inherit version src;
    patches = [ ];
    node_modules = old.node_modules.overrideAttrs {
      inherit version src;
      outputHash = "sha256-fw+sh1g7KuG9UAPVsvRiQLGgGCokrGn9lQ8ox8dnyeY=";
    };
  });
}
