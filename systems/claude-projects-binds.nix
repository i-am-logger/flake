# Each Claude account's projects folder as a bind mount of ~/.claude/projects,
# not a symlink to it (decision 0209; owner: "Bind mount via flake
# (Recommended)"). Claude Code resolves a symlinked path to its target, so a
# memory write through ~/.claude-<account>/projects landed outside that
# account's config folder and drew a permission prompt: 73 of 84 prompts on
# ads-dev1 (.build/productivity-lead/perm/prompts.md). With a bind, the path
# stays inside the account's folder and the files are still the one set.
#
# A oneshot first turns each symlink into a real directory (a mount point must
# not be a symlink). mynixos's claudeAccounts step leaves a non-link alone. The
# mounts are systemd.mounts, not fileSystems, which a VM test overrides.
#
# RETIRING AN ACCOUNT: with a bind, `rm -rf ~/.claude-<account>` while it is
# mounted deletes the shared ~/.claude/projects. Retire by removing the account
# from the host's list and switching: systemd stops (unmounts) its bind first,
# then the folder can go. Never delete a folder that `mountpoint -q` reports.
#
# accounts: config -> [ name ], so a host derives it from its own list.
{ user, accounts, hmUnit ? true }:
{ config, lib, pkgs, utils, ... }:
let
  names = accounts config;
  home = config.users.users.${user}.home;
  group = config.users.users.${user}.group;
  src = "${home}/.claude/projects";
  dir = a: "${home}/.claude-${a}/projects";
  mountUnit = a: "${utils.escapeSystemdPath (dir a)}.mount";
in
{
  systemd.services.claude-projects-mountpoints = {
    description = "Claude accounts' projects folders as directories for their bind mounts (0209)";
    unitConfig.RequiresMountsFor = [ "${home}/.claude" ] ++ map (a: "${home}/.claude-${a}") names;
    before = map mountUnit names;
    serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
    script = ''
      install -d -o ${user} -g ${group} ${lib.escapeShellArg src}
    '' + lib.concatMapStrings
      (a: ''
        p=${lib.escapeShellArg (dir a)}
        if [ -L "$p" ]; then rm -f "$p"; fi
        install -d -o ${user} -g ${group} "$p"
      '')
      names;
    path = [ pkgs.coreutils ];
  };

  systemd.mounts = map
    (a: {
      what = src;
      where = dir a;
      type = "none";
      options = "bind";
      requires = [ "claude-projects-mountpoints.service" ];
      after = [ "claude-projects-mountpoints.service" ];
      unitConfig.RequiresMountsFor = [ "${home}/.claude" ];
      wantedBy = [ "local-fs.target" ];
    })
    names;

  # Home Manager's claudeAccounts step runs after the binds, so it finds a
  # directory (which it leaves) rather than a missing path (which it would link).
  systemd.services."home-manager-${user}".unitConfig.RequiresMountsFor = lib.mkIf hmUnit (map dir names);
}
