---
name: Star placement must respect wall gaps
description: Stars at the same x as a wall must have y inside the wall's gap, otherwise they're physically uncollectable
type: feedback
originSessionId: ec44e418-270a-4227-a9e2-c21fb280b2f7
---
A wall at `x, gap_y, gap_size` is solid except for the strip from
`gap_y - gap_size/2` to `gap_y + gap_size/2`. A star at the same x
with y *outside* that gap is inside the wall's solid section — the
ball can't reach it without dying.

**Rules for placing collectibles relative to walls:**
1. **Same x as wall:** y must be inside the gap. Use `gap_y` (center)
   or `gap_y ± gap_size * 0.4` (anywhere in the gap).
2. **Between walls:** any y in the corridor (roughly 100–700 vertical).
3. **Detour stars (intentionally hard):** place just BEFORE or AFTER
   the wall (different x, ±50–80) at a y *outside* the gap. The
   player must flip to grab it then immediately flip again to enter
   the gap. ~200 ms reaction window at scroll_speed=250.

**Procedural generators** must compute gap bounds before placing stars.
Random `y` over the full corridor will land most stars inside walls.

This bit Gravity Flip's hand-crafted levels 3, 5, 8, 9, 10 (uncollectable
stars marked "Hard — must detour") and the entire procedural generator
for L11+. Fixed in commit after this note's creation.
