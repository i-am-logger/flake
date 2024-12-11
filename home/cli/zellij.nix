{ ... }:
{
  programs.zellij = {
    enable = true;
    enableFishIntegration = true;
    # config = {
    # map-syntax = [ "*.conf:XML" ];
    # };

    # TODO: settings from ~/.config/zellij
    # settings = {
    #   mouse_mode = true;
    #   copy_on_select = true;
    #   scrollback_editor = "hx";
    #   ui.pane_frames.hide_session_name = false;

    # };
  };
}
