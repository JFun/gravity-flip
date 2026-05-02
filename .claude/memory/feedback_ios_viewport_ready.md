---
name: iOS viewport size not ready in _ready()
description: On iOS, get_viewport().get_visible_rect().size is not yet finalized during _ready() — defer viewport-size-dependent setup
type: feedback
originSessionId: ec44e418-270a-4227-a9e2-c21fb280b2f7
---
On iOS, `get_viewport().get_visible_rect().size` returns 0 (or stale) when read inside `_ready()`. Code that computes camera offsets, anchors, or layout from viewport dimensions must `call_deferred()` (or `await get_tree().process_frame`) and ideally retry if size is still <= 1.

**Why:** Real bug — camera offset for left-anchoring the ball silently became 0 on iPhone portrait launch, putting the ball near center instead of 30% from left. Landscape "worked" only because rotating the device fired `size_changed` which recomputed correctly. Dev harness on macOS didn't repro because window size is set explicitly before scene load.

**How to apply:** Any `_ready()` code that reads viewport size — connect to `size_changed` AND `call_deferred` the initial application. Don't trust the first synchronous read.
