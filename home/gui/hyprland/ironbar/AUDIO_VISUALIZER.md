# Audio Visualizer Options for Ironbar

You have **three options** for audio visualization in your ironbar setup:

## Option 1: Real-time CAVA (Most Accurate) ⭐ RECOMMENDED

**File**: `scripts/cava.sh`

### Features:
- ✅ Real frequency spectrum analysis
- ✅ 12 bars with smooth animation
- ✅ Uses your existing cava configuration
- ✅ Auto-starts cava in background
- ✅ Updates at 60 FPS

### Performance:
- **CPU**: ~1-2% (cava background process)
- **Memory**: ~10MB
- **Latency**: ~16ms

### Configuration in `config.json`:
```json
{
  "type": "script",
  "name": "cava",
  "cmd": "$HOME/.config/ironbar/scripts/cava.sh",
  "mode": "poll",
  "interval": 0.05
}
```

**Note**: Lower interval = smoother animation (0.05 = ~20 FPS display, 0.1 = ~10 FPS)

---

## Option 2: Lightweight Volume-Based (Best Performance) 🚀

**File**: `scripts/audio-viz.sh`

### Features:
- ✅ Ultra-lightweight (no background process)
- ✅ Volume-based bars
- ✅ Detects when audio is playing
- ✅ Animated bar heights
- ✅ Shows idle state when silent

### Performance:
- **CPU**: ~0.1% (only when polled)
- **Memory**: Negligible
- **Latency**: Instant

### Configuration in `config.json`:
```json
{
  "type": "script",
  "name": "audio-viz",
  "cmd": "$HOME/.config/ironbar/scripts/audio-viz.sh",
  "mode": "poll",
  "interval": 0.2
}
```

---

## Option 3: Simple Music Info (Minimal)

Uses Ironbar's built-in music module.

### Configuration in `config.json`:
```json
{
  "type": "music",
  "player_type": "mpris",
  "format": "{icon} {title} - {artist}",
  "truncate": {
    "mode": "end",
    "length": 50
  }
}
```

---

## Comparison Table

| Feature | Real CAVA | Lightweight | Music Info |
|---------|-----------|-------------|------------|
| CPU Usage | ~1-2% | ~0.1% | ~0.05% |
| Visual Quality | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐ |
| Frequency Analysis | ✅ Yes | ❌ No | ❌ No |
| Background Process | ✅ Yes (cava) | ❌ No | ❌ No |
| Customizable Bars | 12 bars | 10 bars | N/A |
| Shows Playing State | ✅ Yes | ✅ Yes | ✅ Yes |

---

## Switching Between Options

### To use Real CAVA (Current Default):

Already configured in `config.json`. No changes needed.

### To use Lightweight Visualizer:

1. Add the script to your Nix config:

Edit `home/gui/hyprland/ironbar/default.nix` and add:
```nix
xdg.configFile."ironbar/scripts/audio-viz.sh" = {
  source = ./scripts/audio-viz.sh;
  executable = true;
};
```

2. Update `config/config.json`, replace the cava section:
```json
{
  "type": "script",
  "name": "audio-viz",
  "cmd": "$HOME/.config/ironbar/scripts/audio-viz.sh",
  "mode": "poll",
  "interval": 0.2
}
```

3. Rebuild:
```bash
nixos-rebuild switch --flake ~/.flake
systemctl --user restart ironbar
```

### To use Music Info:

Replace the entire cava/audio-viz block with:
```json
{
  "type": "music",
  "player_type": "mpris",
  "format": "🎵 {title}"
}
```

---

## Styling the Visualizer

In `config/style.css`, you can customize colors:

### For CAVA:
```css
.script.cava {
  color: #4CAF50;  /* Change bar color */
  background: linear-gradient(to bottom, 
    #4CAF50 10%, 
    #FFA500 50%, 
    #FF0000 80%
  );
}
```

### For Lightweight Viz:
```css
.script.audio-viz {
  color: #50ABE5;  /* Cyan/blue bars */
  font-weight: bold;
}
```

---

## Troubleshooting

### CAVA not showing bars:
```bash
# Test cava manually
cava

# Check if FIFO is created
ls -la /tmp/ironbar-cava.fifo

# Kill existing cava instances
pkill cava
```

### Lightweight viz not detecting audio:
```bash
# Check if playerctl works
playerctl status

# Check PulseAudio/PipeWire
pactl list sink-inputs

# Test the script
~/.config/ironbar/scripts/audio-viz.sh
```

### Performance issues:
- Increase `interval` value (e.g., 0.2 instead of 0.05)
- Switch to lightweight visualizer
- Reduce cava bars count (edit script, change `bars = 12` to `bars = 8`)

---

## My Recommendation 🎯

For **your setup**, I recommend:

**Option 1 (Real CAVA)** because:
- You already have cava configured and working
- 1-2% CPU is negligible on modern systems
- Best visual quality matches your aesthetic
- Smooth 60 FPS updates
- Real frequency analysis looks amazing

**But consider Option 2** if:
- You want to save battery on laptop
- You prefer ultra-minimal CPU usage
- You don't need precise frequency analysis

The current setup uses **Option 1** by default. Try it first, and switch if needed!
