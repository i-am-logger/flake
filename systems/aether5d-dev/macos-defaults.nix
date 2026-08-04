# macOS settings for aether5d-dev.
#
# These values were READ OFF THIS MACHINE rather than copied from someone's
# dotfiles, so adopting the config is not supposed to change how the Mac feels.
# Entries marked NEW are genuine changes; everything else is a capture.
#
# Two things to know about how nix-darwin applies these:
#   * user-scoped domains are written as `system.primaryUser` only — there is no
#     per-user fan-out.
#   * the ONLY process nix-darwin restarts is Dock, and only when a dock.* option
#     is set. Finder / menu clock / Control Center / trackpad changes do not take
#     effect until those processes restart or you log out.
{ ... }:

{
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      # 2 = full keyboard access: Tab moves between all controls, not just text
      AppleKeyboardUIMode = 2;
      NSAutomaticCapitalizationEnabled = true;
      NSAutomaticPeriodSubstitutionEnabled = true;
      # Captured from the machine — you changed this after the first pass.
      AppleIconAppearanceTheme = "ClearLight";
      # 2 = large sidebar icons
      NSTableViewDefaultSizeMode = 2;
      "com.apple.sound.beep.feedback" = 1;
      "com.apple.springing.enabled" = true;
      "com.apple.springing.delay" = 0.5;
      "com.apple.trackpad.forceClick" = true;

      # NEW — macOS ships a slow repeat that is painful in a terminal editor.
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
    };

    dock = {
      # You turned this on after the initial capture — the audit caught the
      # drift. Pinned so it survives.
      autohide = true;

      tilesize = 55;
      largesize = 83;
      magnification = true;
      mineffect = "scale";
      # do not reorder spaces by most-recent-use
      mru-spaces = false;
      # bottom-right hot corner = Quick Note
      wvous-br-corner = 14;
      # group Mission Control windows by application
      expose-group-apps = true;

      # Pinned by stable path, never by store path — Discord goes through the
      # /Applications/Nix Apps alias so its tile survives every rebuild.
      persistent-apps = [
        { app = "/System/Applications/Notes.app"; }
        { app = "/System/Applications/Utilities/Terminal.app"; }
        { app = "/Applications/Safari.app"; }
        { app = "/Applications/Nix Apps/Discord.app"; }
        # Was live on the machine but missing here — the real-artifact diff
        # caught it; switching would have silently dropped the tile.
        { app = "/System/Library/CoreServices/Applications/Feedback Assistant.app"; }
      ];
      persistent-others = [ ];
    };

    finder = {
      # Nlsv = list view
      FXPreferredViewStyle = "Nlsv";
      ShowExternalHardDrivesOnDesktop = true;
      ShowHardDrivesOnDesktop = false;
      ShowRemovableMediaOnDesktop = true;
    };

    # Every trackpad option nix-darwin exposes, pinned at its current value —
    # the gestures are stock but pinning them makes the machine reproducible.
    trackpad = {
      # tap-to-click off, two-finger secondary click on
      Clicking = false;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = false;
      FirstClickThreshold = 1;
      SecondClickThreshold = 1;
      ActuateDetents = true;
      Dragging = false;
      DragLock = false;
      ForceSuppressed = false;
      TrackpadCornerSecondaryClick = 0;
      TrackpadMomentumScroll = true;
      TrackpadPinch = true;
      TrackpadRotate = true;
      TrackpadTwoFingerDoubleTapGesture = true;
      TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
      TrackpadThreeFingerHorizSwipeGesture = 2;
      TrackpadThreeFingerVertSwipeGesture = 2;
      TrackpadThreeFingerTapGesture = 0;
      TrackpadFourFingerHorizSwipeGesture = 2;
      TrackpadFourFingerVertSwipeGesture = 2;
      TrackpadFourFingerPinchGesture = 2;
    };

    magicmouse.MouseButtonMode = "OneButton";

    WindowManager = {
      # Stage Manager off — captured; it was unmanaged and would have drifted.
      GloballyEnabled = false;

      # "Click wallpaper to reveal desktop" — OFF.
      # macOS defaults this to true ("Always"), so a stray click on any visible
      # patch of wallpaper shoves every window aside. false means "Only in Stage
      # Manager", which is effectively off while Stage Manager is not running.
      # This is a deliberate change from stock, not a capture.
      EnableStandardClickToShowDesktop = false;

      AutoHide = false;
      AppWindowGroupingBehavior = true;
      HideDesktop = true;
      StandardHideWidgets = false;
      StageManagerHideWidgets = false;
      EnableTiledWindowMargins = true;
    };

    menuExtraClock = {
      ShowSeconds = true;
      # enum, not a bool: 0 = when space allows, 1 = always, 2 = never
      ShowDate = 0;
      ShowAMPM = true;
      ShowDayOfWeek = true;
      IsAnalog = false;
      FlashDateSeparators = true;
    };

    universalaccess = {
      reduceTransparency = false;
      mouseDriverCursorSize = 1.0;
    };

    iCal.CalendarSidebarShown = true;

    # Lock the screen immediately on sleep/screensaver. Effectively already the
    # behaviour here (`sysadminctl -screenLock status` reports "immediate") but
    # unset in the plist, so pinning makes it explicit and reproducible.
    screensaver = {
      askForPassword = true;
      askForPasswordDelay = 0;
    };

    # Already 0 on this machine; pinned so it cannot drift back on.
    loginwindow.GuestEnabled = false;

    # Currently derived from the old ComputerName ("Ido's MacBook Pro" /
    # MAC-E06981). Pinned so they follow the rename deterministically instead of
    # being regenerated. NetBIOS names are uppercase and capped at 15 chars.
    smb = {
      NetBIOSName = "AETHER5D-DEV";
      ServerDescription = "aether5d-dev";
    };

    # Currently 1 on this machine. Left ON to match, but this is the one entry
    # here that is a policy decision rather than a capture — flip it to false if
    # you would rather approve macOS updates yourself.
    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;
  };

  # nix-darwin has no typed options for these three, so they go through the
  # freeform escape hatch. All are 1 on this machine today.
  system.defaults.CustomSystemPreferences."/Library/Preferences/com.apple.SoftwareUpdate" = {
    AutomaticDownload = 1;
    ConfigDataInstall = 1; # security data / XProtect definitions
    CriticalUpdateInstall = 1;
  };

  # alf.* is gone from nix-darwin — the firewall now lives under
  # networking.applicationFirewall.*, which drives socketfilterfw rather than
  # `defaults write`. It is configured in ./default.nix (enabled + stealth mode,
  # a deliberate change: macOS ships it off).
  #
  # controlcenter / screencapture / loginwindow / spaces all read back empty
  # here. Writing stock values would just add noise.
}
