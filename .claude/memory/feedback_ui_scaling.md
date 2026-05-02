---
name: UI font scaling for orientation parity
description: For Godot UI in this project, scale font sizes off the viewport's shorter side so portrait and landscape feel proportionally similar
type: feedback
originSessionId: 81f843f2-db11-4d20-9cfc-764d94a96cda
---
When adding/tuning UI labels or buttons in Gravity Flip, scale `font_size` based on `min(viewport_w, viewport_h) / REFERENCE_SHORT_SIDE` (reference 1080) and clamp to sane min/max. Connect to `get_viewport().size_changed` so it re-applies on rotation. Pattern is in `scripts/ui/hud.gd` and `scripts/ui/death_screen.gd`.

**Why:** Fixed font sizes look proportionally huge in portrait and small in landscape on phones. User validated this approach — said "much better" after applying it to HUD and Game Over panel.

**How to apply:** Default to viewport-relative scaling for any new HUD/menu/overlay text. Don't hardcode `theme_override_font_sizes/font_size` in .tscn files for elements that need to read well across orientations.
