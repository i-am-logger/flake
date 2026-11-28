# account-balance: moves idle Claude sessions in herdr panes off accounts near
# their 5-hour or weekly limit. The mechanism is balance.sh; the names (pools,
# held sessions, thresholds) are config.nix, baked in as a JSON file.
# ACCOUNT_BALANCE_CONFIG still overrides it for a one-off run.
{ lib
, writeShellApplication
, writeText
, herdr
, jq
, util-linux
, procps
, coreutils
, gawk
, gnugrep
, gnused
, taplo
, tzdata
, balanceConfig ? import ./config.nix
}:

let
  configFile = writeText "account-balance.json" (builtins.toJSON balanceConfig);
in
writeShellApplication {
  name = "account-balance";
  runtimeInputs = [ herdr jq util-linux procps coreutils gawk gnugrep gnused tzdata taplo ];
  # No errexit: the script tests with `&&`/`||` chains throughout, as the
  # reference it was adapted from does.
  bashOptions = [ "nounset" "pipefail" ];
  text = ''
    : "''${ACCOUNT_BALANCE_CONFIG:=${configFile}}"
    export ACCOUNT_BALANCE_CONFIG
    : "''${TZDIR:=${tzdata}/share/zoneinfo}"
    export TZDIR
  '' + builtins.readFile ./balance.sh;
  passthru = { inherit configFile; };
  meta = {
    description = "Move idle Claude sessions in herdr panes between accounts by usage";
    platforms = lib.platforms.linux;
    mainProgram = "account-balance";
  };
}
