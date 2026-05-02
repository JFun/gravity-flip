## Heads-up display showing level, stars, and streak.
extends CanvasLayer

const REFERENCE_SHORT_SIDE := 1080.0
const REFERENCE_FONT_SIZE := 80.0
const MIN_FONT_SIZE := 36
const MAX_FONT_SIZE := 96

@onready var level_label: Label = $LevelLabel
@onready var star_label: Label = $StarLabel
@onready var streak_label: Label = $StreakLabel
@onready var mute_button: Button = $MuteButton


func _ready() -> void:
	get_viewport().size_changed.connect(_apply_font_size)
	_apply_font_size()
	# Don't let HUD labels swallow flip-gravity taps.
	for label in [level_label, star_label, streak_label]:
		if label:
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if mute_button:
		mute_button.pressed.connect(_on_mute_pressed)
		AudioManager.mute_changed.connect(_refresh_mute_icon)
		_refresh_mute_icon(AudioManager.muted)


func _on_mute_pressed() -> void:
	AudioManager.toggle_mute()


func _refresh_mute_icon(muted: bool) -> void:
	if mute_button:
		mute_button.text = "✕" if muted else "♪"


func _apply_font_size() -> void:
	var size := get_viewport().get_visible_rect().size
	var short_side: float = min(size.x, size.y)
	var scaled: int = clamp(
		int(round(REFERENCE_FONT_SIZE * short_side / REFERENCE_SHORT_SIDE)),
		MIN_FONT_SIZE,
		MAX_FONT_SIZE,
	)
	for label in [level_label, star_label, streak_label]:
		if label:
			label.add_theme_font_size_override("font_size", scaled)


func update_display(level: int, stars: int, streak: int) -> void:
	if level_label:
		level_label.text = "L%d" % level
	if star_label:
		star_label.text = "★ %d" % stars
	if streak_label:
		streak_label.text = "x %d" % streak if streak > 1 else ""
