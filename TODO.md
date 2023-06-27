power management
- powertop tool is helpful
- thinkpad t470s power management on nixos at discourse.noxos.org

# pt everything in ram 
make sure all .config changes are wiped with reboot

# cacheix 

# home manager

# Hyprland configuration

https://wiki.hyprland.org/Nix

https://github.com/Aylur/dotfiles/tree/main/.config/hypr

## wallpaper - hyprpaper
## Screenshot
              "Print" = "exec ${grimshot} --notify save screen $(${xdg-user-dir} PICTURES)/$(TZ=utc date +'screenshot_%Y-%m-%d-%H%M%S.%3N.png')"; # All visible outputs
              "Shift+Print" = "exec ${grimshot} --notify save area $(${xdg-user-dir} PICTURES)/$(TZ=utc date +'screenshot_%Y-%m-%d-%H%M%S.%3N.png')"; # Manually select a region
              "Alt+Print" = "exec ${grimshot} --notify save active $(${xdg-user-dir} PICTURES)/$(TZ=utc date +'screenshot_%Y-%m-%d-%H%M%S.%3N.png')"; # Currently active window
              "Shift+Alt+Print" = "exec ${grimshot} --notify save window $(${xdg-user-dir} PICTURES)/$(TZ=utc date +'screenshot_%Y-%m-%d-%H%M%S.%3N.png')"; # Manually select a window
              "Ctrl+Print" = "exec ${grimshot} --notify copy screen";
              "Ctrl+Shift+Print" = "exec ${grimshot} --notify copy area";
              "Ctrl+Alt+Print" = "exec ${grimshot} --notify copy active";
              "Ctrl+Shift+Alt+Print" = "exec ${grimshot} --notify copy window";
              ## Screen recording
              "${modifier}+Print" = "exec wayrecorder --notify screen";
              "${modifier}+Shift+Print" = "exec wayrecorder --notify --input area";
              "${modifier}+Alt+Print" = "exec wayrecorder --notify --input active";
              "${modifier}+Shift+Alt+Print" = "exec wayrecorder --notify --input window";
              "${modifier}+Ctrl+Print" = "exec wayrecorder --notify --clipboard --input screen";
              "${modifier}+Ctrl+Shift+Print" = "exec wayrecorder --notify --clipboard --input area";
              "${modifier}+Ctrl+Alt+Print" = "exec wayrecorder --notify --clipboard --input active";
              "${modifier}+Ctrl+Shift+Alt+Print" = "exec wayrecorder --notify --clipboard --input window";
