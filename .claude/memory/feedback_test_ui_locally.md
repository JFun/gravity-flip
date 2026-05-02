---
name: Verify UI changes locally before deploying
description: Use the dev screenshot harness (or equivalent) to verify UI changes at portrait+landscape before flashing to device
type: feedback
originSessionId: 81f843f2-db11-4d20-9cfc-764d94a96cda
---
Before claiming a UI change is done, render it locally and inspect it. Don't ship UI tweaks without seeing them.

**Why:** I broke a panel layout (overflowed off-screen in portrait) after sizing it from `max(viewport.x, viewport.y)` instead of `viewport.x` — would have caught this in 30s by looking. User called this out: "make sure you test ui by yourself."

**How to apply:** For Godot UI changes, use [scripts/dev/ui_screenshot.gd](../../../git/gravity_flip/scripts/dev/ui_screenshot.gd) — runs the game scene at a chosen window size, force-shows a panel, dumps PNG to `user://`. Invoke with `godot --path . --script scripts/dev/ui_screenshot.gd -- <portrait|landscape> <clear|over>`. Saved PNG path is printed; read it back with the Read tool to view. Build the harness if it doesn't exist for the case you need.

Sizing trap to remember: with stretch=`canvas_items` + aspect=`expand`, `get_visible_rect().size` is design units that grow on the long axis. Panel width should come from `size.x` (the actual width), not `max(size.x, size.y)` — the latter overflows in portrait.
