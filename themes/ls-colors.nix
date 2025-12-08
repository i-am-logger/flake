{ config, lib, ... }:

with lib;

let
  cfg = config.stylix.ls-colors;

  hexDigitToInt =
    c:
    let
      hexChars = "0123456789abcdef";
    in
    stringLength (head (splitString c (toLower hexChars)));

  hexToRgb =
    hexColor:
    let
      r = substring 0 2 hexColor;
      g = substring 2 2 hexColor;
      b = substring 4 2 hexColor;
      toDecimal = hex: hexDigitToInt (substring 0 1 hex) * 16 + hexDigitToInt (substring 1 1 hex);
    in
    "${toString (toDecimal r)};${toString (toDecimal g)};${toString (toDecimal b)}";

  generateLsColors =
    colors:
    let
      mkColor = color: "38;2;${hexToRgb color}";
      colorMap = {
        # Special files and directories
        di = mkColor colors.base0D; # directory
        fi = mkColor colors.base05; # regular file
        # ln = mkColor colors.base0E; # symbolic link
        ex = mkColor colors.base0B; # executable file
        bd = mkColor colors.base0A; # block device
        cd = mkColor colors.base0A; # character device
        so = mkColor colors.base0A; # socket
        pi = mkColor colors.base0A; # named pipe (FIFO)
        or = mkColor colors.base08; # orphaned symlink
        mi = mkColor colors.base08; # missing file
        su = mkColor colors.base0C; # file that is setuid (u+s)
        sg = mkColor colors.base0C; # file that is setgid (g+s)
        ca = mkColor colors.base0C; # file with capability
        tw = mkColor colors.base0A; # directory that is sticky and other-writable (+t,o+w)
        ow = mkColor colors.base0A; # directory that is other-writable (o+w) and not sticky
        st = mkColor colors.base0E; # directory with sticky bit set (+t) and not other-writable
        ee = mkColor colors.base09; # empty file (arrow for classifyAlt)
        no = mkColor colors.base05; # normal non-filename text
        rs = mkColor colors.base05; # reset to no color
        mh = mkColor colors.base05; # multi-hardlink
        lc = mkColor colors.base05; # left code (opening part of color sequence)
        rc = mkColor colors.base05; # right code (closing part of color sequence)
        ec = mkColor colors.base05; # end code (for non-filename text)
        # File extensions
        # "*.bash" = mkColor colors.base05;
        "*.bz2" = mkColor colors.base09;
        # "*.c" = mkColor colors.base0C;
        "*.cfg" = mkColor colors.base07;
        # "*.class" = mkColor colors.base0C;
        "*.conf" = mkColor colors.base07;
        # "*.cpp" = mkColor colors.base0C;
        # "*.cs" = mkColor colors.base0C;
        # "*.css" = mkColor colors.base0C;
        # "*.deb" = mkColor colors.base0C;
        "*.doc" = mkColor colors.base07;
        "*.docx" = mkColor colors.base07;
        "*.flac" = mkColor colors.base0E;
        "*.gif" = mkColor colors.base0E;
        # "*.go" = mkColor colors.base0C;
        "*.gz" = mkColor colors.base09;
        # "*.h" = mkColor colors.base0C;
        # "*.html" = mkColor colors.base0C;
        "*.ini" = mkColor colors.base07;
        # "*.java" = mkColor colors.base0C;
        "*.jpeg" = mkColor colors.base0E;
        "*.jpg" = mkColor colors.base0E;
        # "*.js" = mkColor colors.base0C;
        "*.json" = mkColor colors.base07;
        # "*.less" = mkColor colors.base0C;
        # "*.lua" = mkColor colors.base0C;
        "*.md" = mkColor colors.base07;
        "*.mp3" = mkColor colors.base0E;
        "*.mp4" = mkColor colors.base0E;
        "*.nix" = mkColor colors.base0C;
        # "*.odt" = mkColor colors.base08;
        # "*.ogg" = mkColor colors.base07;
        "*.pdf" = mkColor colors.base07;
        "*.png" = mkColor colors.base0E;
        # "*.py" = mkColor colors.base0C;
        # "*.rb" = mkColor colors.base0C;
        # "*.rpm" = mkColor colors.base08;
        # "*.rs" = mkColor colors.base0C;
        # "*.scss" = mkColor colors.base0C;
        # "*.sh" = mkColor colors.base0C;
        # "*.sql" = mkColor colors.base0C;
        "*.svg" = mkColor colors.base0E;
        "*.tar" = mkColor colors.base09;
        "*.tgz" = mkColor colors.base09;
        # "*.ts" = mkColor colors.base0C;
        "*.txt" = mkColor colors.base07;
        "*.toml" = mkColor colors.base07;
        # "*.vim" = mkColor colors.base0C;
        "*.wav" = mkColor colors.base0E;
        "*.xml" = mkColor colors.base07;
        "*.yaml" = mkColor colors.base07;
        "*.yml" = mkColor colors.base07;
        "*.zip" = mkColor colors.base09;
        "*.iso" = mkColor colors.base09;
        "*.zst" = mkColor colors.base09;
        # "*.zsh" = mkColor colors.base0C;
      };
    in
    concatStringsSep ":" (mapAttrsToList (k: v: "${k}=${v}") colorMap);

in
{
  options.stylix.ls-colors = {
    enable = mkEnableOption "Stylix-based LS_COLORS";
  };

  config = mkIf cfg.enable {
    environment.sessionVariables = {
      LS_COLORS = generateLsColors config.lib.stylix.colors;
    };

    environment.extraInit = ''
      export LS_COLORS="${generateLsColors config.lib.stylix.colors}"
    '';

    programs.bash.interactiveShellInit = ''
      export LS_COLORS="${generateLsColors config.lib.stylix.colors}"
    '';

    programs.zsh.interactiveShellInit = mkIf config.programs.zsh.enable ''
      export LS_COLORS="${generateLsColors config.lib.stylix.colors}"
    '';

    programs.fish.interactiveShellInit = mkIf config.programs.fish.enable ''
      set -gx LS_COLORS "${generateLsColors config.lib.stylix.colors}"
    '';
  };
}
