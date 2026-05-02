## Level-clear panel shown between levels.
extends CanvasLayer

signal continue_pressed

const REFERENCE_SHORT_SIDE := 1080.0
const STARS_REF_SIZE := 56.0
const STREAK_REF_SIZE := 44.0
const BUTTON_REF_SIZE := 72.0
const PANEL_WIDTH_RATIO := 0.75  ## Panel width = 75% of viewport width.
const PANEL_MIN_W := 420.0
const PANEL_MAX_W := 1200.0

@onready var panel: PanelContainer = $CenterContainer/PanelContainer
@onready var stars_label: Label = $CenterContainer/PanelContainer/VBoxContainer/StarsLabel
@onready var streak_label: Label = $CenterContainer/PanelContainer/VBoxContainer/StreakLabel
@onready var continue_button: Button = $CenterContainer/PanelContainer/VBoxContainer/ContinueButton


func _ready() -> void:
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
	get_viewport().size_changed.connect(_apply_layout)
	_apply_layout()


func _apply_layout() -> void:
	var size := get_viewport().get_visible_rect().size
	var scale: float = min(size.x, size.y) / REFERENCE_SHORT_SIDE
	_set_size(stars_label, STARS_REF_SIZE * scale, 24, 80)
	_set_size(streak_label, STREAK_REF_SIZE * scale, 22, 64)
	_set_size(continue_button, BUTTON_REF_SIZE * scale, 32, 96)
	if panel:
		var w: float = clamp(size.x * PANEL_WIDTH_RATIO, PANEL_MIN_W, PANEL_MAX_W)
		panel.custom_minimum_size = Vector2(w, 0)


func _set_size(ctrl: Control, raw: float, lo: int, hi: int) -> void:
	if ctrl:
		ctrl.add_theme_font_size_override("font_size", clamp(int(round(raw)), lo, hi))


func show_screen(cleared_level: int, next_level: int, stars: int, streak: int) -> void:
	visible = true
	if stars_label:
		stars_label.text = "★ %d" % stars
	if streak_label:
		streak_label.text = "Best streak: x %d" % streak
	if continue_button:
		continue_button.text = "Level %d" % next_level

	if panel:
		panel.pivot_offset = panel.size * 0.5
		panel.modulate.a = 0.0
		panel.scale = Vector2(0.88, 0.88)
		var tween := create_tween().set_parallel(true)
		tween.tween_property(panel, "modulate:a", 1.0, 0.25)
		tween.tween_property(panel, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_OUT)


func hide_screen() -> void:
	visible = false


func _on_continue_pressed() -> void:
	continue_pressed.emit()
