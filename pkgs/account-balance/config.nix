# account-balance's config: data, written to JSON and baked into the wrapper.
#
# An account is `default` (~/.claude with CLAUDE_CONFIG_DIR unset) or a name N
# (~/.claude-N). Pool `main` is cdev1-cdev4, where cdev4 IS `default`: there is
# no ~/.claude-cdev4. Moves stay inside one pool.
{
  pools = {
    main = [ "cdev1" "cdev2" "cdev3" "default" ];
    # Held empty: a login is used by one host only, and the split of these
    # logins between hosts is an owner call that has not been made.
    aether5d = [ ];
  };

  # herdr sessions whose panes are reported by `status` and never planned or
  # moved.
  held_sessions = [ "aether5d" ];

  thresholds = {
    high = 70; # 5-hour % at or above which an account is a source
    low = 30; # 5-hour % below which an account can be a target
    week_high = 85; # weekly % at or above which an account is a source
    week_low = 75; # weekly % at or above which an account is never a target
    stale_min = 90; # a reading older than this (minutes) is never trusted
    per_target = 1; # moves landing on one account per run
    max = 3; # moves per run
  };
}
