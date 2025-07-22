{
  ...
}:

{
  programs.lsd = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      date = "+%y-%m-%d %H:%M:%S";
      indicators = true;
      recursion = {
        depth = 2;
      };
      sorting = {
        dir-grouping = "first";
      };
      symlink-arrow = "~>";
      header = true;
      classic = false;
      color = {
        when = "auto";
      };
      icons = {
        when = "auto";
      };
      hyperlink = "auto";
      blocks = [
        "permission"
        "user"
        "group"
        # "context"
        "size"
        "date"
        "name"
        # "inode"
        # "links"
      ];
    };
  };
}
