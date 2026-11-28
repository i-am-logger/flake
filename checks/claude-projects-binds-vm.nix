# Decision 0209, booted. ~/.claude-cdev1/projects starts as mynixos leaves it, a
# symlink to ~/.claude/projects. A memory write through the account's path must
# keep its real path inside ~/.claude-cdev1, which is what Claude Code's
# permission check sees, and must be the same file as under ~/.claude/projects.
# withFix = false is the red: the symlink alone. A VM test, so it's in `tests`.
{ pkgs, lib ? pkgs.lib, withFix }:
pkgs.testers.runNixOSTest {
  name = "claude-projects-binds-${if withFix then "fixed" else "unfixed"}";
  nodes.machine = { lib, ... }: {
    imports = lib.optional withFix (import ../systems/claude-projects-binds.nix {
      user = "logger";
      accounts = _: [ "cdev1" ];
      hmUnit = false;
    });
    users.users.logger = { isNormalUser = true; };
    # The layout mynixos's claudeAccounts step leaves: the projects symlink.
    # After the users step, so the owner exists.
    system.activationScripts.claudeLayout = {
      deps = [ "users" ];
      text = ''
        install -d -o logger -g users /home/logger/.claude/projects /home/logger/.claude-cdev1
        [ -e /home/logger/.claude-cdev1/projects ] || ln -s /home/logger/.claude/projects /home/logger/.claude-cdev1/projects
      '';
    };
  };
  testScript = ''
    machine.wait_for_unit("multi-user.target")
    kind = machine.succeed("stat -c %F /home/logger/.claude-cdev1/projects").strip()
    print("projects is a:", kind)
    ${if withFix then "" else ''assert kind == "symbolic link", f"the test's starting layout is wrong: {kind}"''}
    machine.succeed("su logger -c 'mkdir -p ~/.claude-cdev1/projects/p/memory && echo note > ~/.claude-cdev1/projects/p/memory/a.md'")
    real = machine.succeed("realpath /home/logger/.claude-cdev1/projects/p/memory/a.md").strip()
    print("realpath:", real)
    assert real.startswith("/home/logger/.claude-cdev1/"), f"the write resolves outside the account folder: {real}"
    assert machine.succeed("cat /home/logger/.claude/projects/p/memory/a.md").strip() == "note", "not the same files"
    machine.succeed("findmnt -n /home/logger/.claude-cdev1/projects")
    ${lib.optionalString withFix ''
      # Retiring the account the safe way: its bind stops (as a switch without it
      # does), then the folder goes; the shared projects must survive.
      machine.succeed("systemctl stop /home/logger/.claude-cdev1/projects")
      machine.succeed("! mountpoint -q /home/logger/.claude-cdev1/projects")
      machine.succeed("rm -rf /home/logger/.claude-cdev1")
      assert machine.succeed("cat /home/logger/.claude/projects/p/memory/a.md").strip() == "note", "retiring the account deleted the shared projects"
    ''}
  '';
}
