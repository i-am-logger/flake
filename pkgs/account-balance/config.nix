# account-balance's config: data, written to JSON and baked into the wrapper.
#
# An account is `default` (~/.claude with CLAUDE_CONFIG_DIR unset) or a name N (~/.claude-N). In
# ledger/accounts.tsv `cdev4` IS `default`: there is no ~/.claude-cdev4. Moves stay inside one pool.
{
  pools = {
    main = [ "cdev1" "cdev2" "cdev3" "default" "cdev5" "cdev6" ];
  };

  # Never targets: default is shared with the Mac and yoga and kept light (0161, 0166); the temporary
  # accounts are drained (0188).
  source_only = [ "default" ];
  temporary = [ "cdev5" "cdev6" ];
  # The temporary period ends at the latest next weekly reset of these accounts, latched by the first
  # run that reads them (state drain-after.epoch).
  drain_after_resets_of = [ "cdev3" "default" ];

  # herdr sessions whose panes are reported by `status` and never planned or moved.
  held_sessions = [ "aether5d" ];

  thresholds = {
    room = 70; # weekly % (and 5-hour %) at or above which an account is never a target
    hysteresis = 2; # a move S -> T needs rate(T) >= hysteresis x rate(S)
    stale_min = 90; # a reading older than this (minutes) is never trusted
    per_target = 1; # moves landing on one account per run
    max = 3; # moves per run
    breaker = 2; # failed moves that stop a run
  };
}
