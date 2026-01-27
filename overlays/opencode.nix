# Override opencode to v1.1.35
# Auto-updated by scripts/update-opencode.sh
final: prev:
let
  version = "1.1.35";
  src = prev.fetchFromGitHub {
    owner = "anomalyco";
    repo = "opencode";
    tag = "v${version}";
    hash = "sha256-z8RnhFbdtZPb05l1gdgKXCOBDgRNZyppgzrFRNq4wmg=";
  };
in
{
  opencode = prev.opencode.overrideAttrs (old: {
    inherit version src;
    node_modules = old.node_modules.overrideAttrs {
      inherit version src;
      outputHash = "sha256-IlRtdiY6kpscHcFNcmI5dW3LbRh9e+3PpafNPM7wTIA=";
    };
  });
}
