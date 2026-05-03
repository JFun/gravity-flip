---
name: Visual consistency between HUD icons and in-game objects
description: HUD glyph and the in-game object it represents must look like the same thing — a ★ in the HUD demands a star polygon in the world, not a square ColorRect placeholder
type: feedback
originSessionId: ec44e418-270a-4227-a9e2-c21fb280b2f7
---
Players read the HUD as a key to the world. If the HUD says "★ 0" but
the collectible in the world is a yellow square, the connection breaks
and the square reads as "yellow thing" rather than "star."

**Default to drawing the actual shape.** `ColorRect` is fine for blocky
hazards (walls, spikes) but wrong for anything the HUD names. For a
star use `Polygon2D` with a 5-point star polygon (alternating outer
and inner radii, starting from `-PI/2` for an upright star).

```gdscript
func _star_polygon(outer_r: float, inner_r: float) -> PackedVector2Array:
    var pts := PackedVector2Array()
    var points := 5
    for i in points * 2:
        var r: float = outer_r if i % 2 == 0 else inner_r
        var angle: float = -PI / 2.0 + i * PI / points
        pts.append(Vector2(cos(angle) * r, sin(angle) * r))
    return pts
```

Apply the same rule to anything else: heart pickups should be a heart
polygon, coins should be circles, gem icons should match a polygon, etc.
