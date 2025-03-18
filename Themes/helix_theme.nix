{ config, lib, pkgs, ... }:
{
  stylix.programs.helix = {
    themes = {
      stylix = {
        inherits = "base16";
        
        # Make all syntax elements use the same color
        "attribute" = { fg = "base05"; };
        "constant" = { fg = "base05"; };
        "constant.character.escape" = { fg = "base05"; };
        "constant.numeric" = { fg = "base05"; };
        "constructor" = { fg = "base05"; };
        "function" = { fg = "base05"; };
        "keyword" = { fg = "base05"; };
        "label" = { fg = "base05"; };
        "namespace" = { fg = "base05"; };
        "operator" = { fg = "base05"; };
        "special" = { fg = "base05"; };
        "string" = { fg = "base05"; };
        "type" = { fg = "base05"; };
        "variable" = { fg = "base05"; };
        "variable.other.member" = { fg = "base05"; };
        
        # Comments slightly dimmed
        "comment" = { fg = "base03"; modifiers = ["italic"]; };
        
        # Important indicators only
        "error" = { fg = "base08"; };                    # Red for errors
        "warning" = { fg = "base0A"; };                  # Yellow for warnings
        "info" = { fg = "base0D"; };                     # Blue for info
        "hint" = { fg = "base0E"; };                     # Purple for hints
        
        # Diagnostics
        "diagnostic.error" = { fg = "base08"; underline = { style = "curl"; }; };
        "diagnostic.warning" = { fg = "base0A"; underline = { style = "curl"; }; };
        "diagnostic.info" = { fg = "base0D"; underline = { style = "curl"; }; };
        "diagnostic.hint" = { fg = "base0E"; underline = { style = "curl"; }; };
        
        # Diff indicators
        "diff.plus" = { fg = "base0B"; };               # Green for additions
        "diff.minus" = { fg = "base08"; };              # Red for deletions
        "diff.delta" = { fg = "base0A"; };              # Yellow for changes
        
        # UI elements
        "ui.cursor" = { fg = "base00"; bg = "base05"; };
        "ui.cursor.match" = { fg = "base05"; modifiers = ["bold"]; };
        "ui.cursor.primary" = { fg = "base00"; bg = "base05"; };
        "ui.selection" = { bg = "base02"; };
        "ui.linenr" = { fg = "base03"; };
        "ui.linenr.selected" = { fg = "base04"; };
        "ui.statusline" = { fg = "base04"; bg = "base01"; };
        "ui.statusline.normal" = { fg = "base04"; bg = "base01"; };
        "ui.statusline.insert" = { fg = "base0B"; bg = "base01"; };
        "ui.statusline.select" = { fg = "base0D"; bg = "base01"; };
        "ui.popup" = { bg = "base01"; };
        "ui.window" = { bg = "base01"; };
        "ui.help" = { bg = "base01"; fg = "base05"; };
        
        # Minimal markup
        "markup.heading" = { fg = "base05"; modifiers = ["bold"]; };
        "markup.list" = { fg = "base05"; };
        "markup.bold" = { fg = "base05"; modifiers = ["bold"]; };
        "markup.italic" = { fg = "base05"; modifiers = ["italic"]; };
        "markup.link.url" = { fg = "base05"; modifiers = ["underlined"]; };
        "markup.link.text" = { fg = "base05"; };
        "markup.quote" = { fg = "base05"; };
        "markup.raw" = { fg = "base05"; };
      };
    };
  };
}
