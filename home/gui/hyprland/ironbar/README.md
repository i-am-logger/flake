# Ironbar Configuration

This ironbar setup replicates your waybar configuration with high performance.

## Bars

### Top Bar (`config.json`)
- **Left**: Hyprland workspaces (1-9)
- **Center**: Clock, weather widget
- **Right**: Privacy indicators, network, volume, audio visualizer, battery, battery time, system tray

### Bottom Bar (`config-bottom.json`)
- **Left**: Disk usage (/boot, /nix, /tmp, /), memory, CPU, temperature, network bandwidth

### Bottom Window Bar (`config-bottom-window.json`)
- **Left**: Active window title
- **Right**: Keyboard layout, caps lock indicator

## Features

✅ Native Hyprland workspace support
✅ Real-time system monitoring with color-coded indicators
✅ Network bandwidth monitoring
✅ Privacy indicators (screenshare, microphone)
✅ Weather integration
✅ Battery with charging states
✅ System tray support
✅ Keyboard state indicators

## Scripts

All scripts are located in `scripts/` directory:
- `weather.sh` - Weather from wttr.in
- `privacy.sh` - Privacy monitoring (screenshare/mic)
- `cava.sh` - Audio visualizer (simplified)
- `memory.sh` - Memory usage with color coding
- `cpu.sh` - CPU usage with color coding
- `temperature.sh` - Temperature monitoring
- `network-bandwidth.sh` - Network upload/download rates
- `keyboard-state.sh` - Caps lock indicator

## Styling

The `style.css` file matches your original waybar theme:
- Black background (#000000)
- Colored text based on state
- Custom workspace styling
- Color-coded system monitoring

## Usage

After rebuilding your NixOS configuration:

```bash
# Rebuild your system
nixos-rebuild switch --flake ~/.flake

# The ironbar service will start automatically with Hyprland
# To manually restart:
systemctl --user restart ironbar

# To check status:
systemctl --user status ironbar

# View logs:
journalctl --user -u ironbar -f
```

## Differences from Waybar

1. **Performance**: Ironbar is written in Rust and uses less CPU/memory
2. **Native Hyprland**: Better integration with Hyprland's IPC
3. **Configuration**: JSON-based instead of JSON5
4. **Multiple bars**: Each bar has its own config file
5. **Scripts**: Some modules use scripts for custom functionality

## Customization

To customize:
1. Edit `config/*.json` for bar layout and modules
2. Edit `style.css` for appearance
3. Edit `scripts/*.sh` for custom script behavior

## Notes

- The cava visualization is simplified - full cava integration would require additional setup
- Weather updates every 5 minutes (300 seconds)
- Privacy indicators check for active screenshare/microphone
- Color-coded bars match your original waybar theme
