# account-balance's config: data, written to JSON and baked into the wrapper.
#
# An account is `default` (~/.claude with CLAUDE_CONFIG_DIR unset) or a name N (~/.claude-N). In
# ledger/accounts.tsv `cdev4` IS `default`: there is no ~/.claude-cdev4. Moves stay inside one pool.
{
  # Each team's home accounts are head's: [teams.<team>].accounts in
  # ~/Code/logger/team-roles.toml (the registry), not here.

  # Never targets: default is shared with the Mac and yoga and kept light (0161, 0166); the temporary
  # accounts are drained (0188).
  source_only = [ "default" ];
  temporary = [ "cdev5" "cdev6" ];
  # The temporary period ends at the latest next weekly reset of these accounts, latched by the first
  # run that reads them (state drain-after.epoch).
  drain_after_resets_of = [ "cdev3" "default" ];

  # herdr sessions whose panes are reported by `status` and never planned or moved.
  held_sessions = [ "aether5d" ];

  # Panes named with these prefixes are pinned to their account, never moved:
  # the Accounts consoles (account-cdevN; acct-cdevN on skyspy-dev), where
  # bin/account-usage reads each account's /usage.
  pinned_name_prefixes = [ "account-" "acct-" ];

  thresholds = {
    room = 70; # weekly % (and 5-hour %) at or above which an account is never a target
    overflow_home_over = 85; # every home account over this: borrow (head, 11-28)
    hysteresis = 2; # a move S -> T needs rate(T) >= hysteresis x rate(S)
    stale_min = 90; # a reading older than this (minutes) is never trusted
    per_target = 1; # moves landing on one account per run
    max = 3; # moves per run
    breaker = 2; # failed moves that stop a run
  };
}
