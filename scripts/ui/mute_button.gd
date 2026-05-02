## Mute toggle button: draws a diagonal slash through the ♪ glyph when muted.
##
## Color-only state indication is fragile (colorblind users, ambiguous semantics)
## and emoji glyphs (🔊/🔇) aren't in Open Sans so they render blank. A
## slash-through icon is the universal "off / disabled" convention and reads
## the same in greyscale.
extends Button


var muted: bool = false:
	set(value):
		if muted == value:
			return
		muted = value
		queue_redraw()


func _draw() -> void:
	if not muted:
		return
	# Draw the slash centered on the button, sized off the current font so it
	# scales with the ♪ glyph rather than the button's wide hit-target rect.
	var center: Vector2 = size * 0.5
	var font_size: int = get_theme_font_size("font_size")
	if font_size <= 0:
		font_size = 80
	var slash_len: float = float(font_size) * 0.55
	var thickness: float = max(3.0, float(font_size) * 0.06)
	var color := get_theme_color("font_color")
	# "\" direction (top-left to bottom-right) — standard prohibition slash.
	var half := Vector2(slash_len, slash_len) * 0.5
	draw_line(center - half, center + half, color, thickness, true)
