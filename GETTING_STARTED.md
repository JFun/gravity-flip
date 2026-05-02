# Gravity Flip — Getting Started

## Quick Start

1. **Open the project** — Launch Godot 4.3+, click "Import", navigate to this folder, select `project.godot`
2. **Hit Play (F5)** — The game runs immediately. Tap/click/spacebar to flip gravity.
3. **You're playing Level 1.** Navigate through gaps by flipping gravity.

## Project Structure

```
gravity_flip/
├── project.godot              # Godot project config
├── scenes/
│   └── game.tscn              # Main scene (Player + Floor + Ceiling + HUD + DeathScreen)
├── scripts/
│   ├── player.gd              # Core player controller (flip mechanic, physics, death)
│   ├── game.gd                # Game manager (level loading, scoring, state)
│   └── ui/
│       ├── hud.gd             # Score/level display
│       └── death_screen.gd    # Game over overlay
├── levels/
│   └── level_data.gd          # All 10 hand-crafted levels + procedural generator
└── assets/
    ├── sounds/                # Add .wav/.ogg files here
    └── themes/                # Add visual themes here
```

## Controls

| Input          | Action        |
|----------------|---------------|
| Tap (mobile)   | Flip gravity  |
| Left click     | Flip gravity  |
| Spacebar       | Flip gravity  |

## How the Code Works

### Player (scripts/player.gd)
- **Gravity flip**: `gravity_dir` toggles between `1.0` (down) and `-1.0` (up) on input
- **Auto-scroll**: Ball moves right at constant `scroll_speed`
- **Death**: Triggered when colliding with anything in the "hazard" group
- **Juice**: Screen shake, 180° rotation tween, trail color change on each flip

### Levels (levels/level_data.gd)
- Levels 1–10 are hand-crafted dictionaries
- Levels 11+ use seeded procedural generation
- Each level defines obstacles, stars, orbs, and total length
- The `game.gd` script reads level data and spawns obstacles at runtime

### Adding a New Level
Edit `level_data.gd` and add a new function:

```gdscript
static func level_11() -> Dictionary:
    return {
        "name": "Moving Walls",
        "obstacles": [
            {"type": "wall", "x": 300, "gap_y": 400, "gap_size": 200},
            # Add more obstacles...
        ],
        "stars": [
            {"x": 300, "y": 250},
        ],
        "orbs": [],
        "length": 1500,
    }
```

Then update the `get_level()` match statement to include `11: return level_11()`.

## Next Steps (Your First Week)

### Day 1-2: Make it feel good
- [ ] Add a ball sprite (32x32 circle PNG) to replace the default
- [ ] Add a flip sound effect (.ogg file, play in `_do_flip()`)
- [ ] Add a death sound effect
- [ ] Tweak `gravity_strength` and `scroll_speed` until the flip feels satisfying

### Day 3-4: Polish the visuals
- [ ] Create a proper ball sprite with a glow effect
- [ ] Add a GPUParticles2D material to the Trail node (circular, small, fading)
- [ ] Color the floor/ceiling with a gradient
- [ ] Add parallax background layers

### Day 5-7: Content
- [ ] Playtest levels 1-10, adjust gap sizes if too hard/easy
- [ ] Add levels 11-20 (introduce moving walls — see design doc)
- [ ] Add star collection sound + visual feedback
- [ ] Test on a real phone via Godot's remote debug

## Key Values to Tweak

| Variable                | File        | Default | What it does                          |
|-------------------------|-------------|---------|---------------------------------------|
| `gravity_strength`      | player.gd   | 980     | How fast ball accelerates             |
| `max_fall_speed`        | player.gd   | 800     | Terminal velocity                     |
| `scroll_speed`          | player.gd   | 250     | How fast the level scrolls            |
| `flip_rotation_time`    | player.gd   | 0.12    | Ball rotation animation speed         |
| `flip_screen_shake`     | player.gd   | 3.0     | Shake intensity on flip               |
| `flip_cooldown`         | player.gd   | 0.0     | Set to 0.3 for Zone 4+ difficulty     |
| `scroll_speed_increment`| game.gd     | 5.0     | Speed increase per level              |
| `gap_size` (per level)  | level_data  | varies  | Larger = easier, smaller = harder     |

## Exporting to Mobile

1. Install Android/iOS export templates in Godot (Editor → Manage Export Templates)
2. Project → Export → Add Android or iOS preset
3. Set orientation to Portrait
4. Build and run on device

The touch input is already wired up in `player.gd` via `InputEventScreenTouch`.
