## Death / game over overlay.
extends CanvasLayer

signal retry_pressed
signal reset_progress_pressed

const REFERENCE_SHORT_SIDE := 1080.0
const TITLE_REF_SIZE := 80.0
const LEVEL_REF_SIZE := 52.0
const STARS_REF_SIZE := 56.0
const STREAK_REF_SIZE := 44.0
const BUTTON_REF_SIZE := 72.0
const RESET_REF_SIZE := 30.0
const PANEL_WIDTH_RATIO := 0.75
const PANEL_MIN_W := 420.0
const PANEL_MAX_W := 1200.0

@onready var panel: PanelContainer = $CenterContainer/PanelContainer
@onready var title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/TitleLabel
@onready var level_label: Label = $CenterContainer/PanelContainer/VBoxContainer/LevelLabel
@onready var stars_label: Label = $CenterContainer/PanelContainer/VBoxContainer/StarsLabel
@onready var streak_label: Label = $CenterContainer/PanelContainer/VBoxContainer/StreakLabel
@onready var retry_button: Button = $CenterContainer/PanelContainer/VBoxContainer/RetryButton
@onready var reset_button: Button = $CenterContainer/PanelContainer/VBoxContainer/ResetButton


func _ready() -> void:
	if retry_button:
		retry_button.pressed.connect(_on_retry_pressed)
	if reset_button:
		reset_button.pressed.connect(_on_reset_pressed)
	get_viewport().size_changed.connect(_apply_font_sizes)
	_apply_font_sizes()


func _apply_font_sizes() -> void:
	var size := get_viewport().get_visible_rect().size
	var scale: float = min(size.x, size.y) / REFERENCE_SHORT_SIDE
	_set_size(title_label, TITLE_REF_SIZE * scale, 36, 108)
	_set_size(level_label, LEVEL_REF_SIZE * scale, 24, 72)
	_set_size(stars_label, STARS_REF_SIZE * scale, 24, 80)
	_set_size(streak_label, STREAK_REF_SIZE * scale, 22, 64)
	_set_size(retry_button, BUTTON_REF_SIZE * scale, 32, 96)
	_set_size(reset_button, RESET_REF_SIZE * scale, 18, 40)
	if panel:
		var w: float = clamp(size.x * PANEL_WIDTH_RATIO, PANEL_MIN_W, PANEL_MAX_W)
		panel.custom_minimum_size = Vector2(w, 0)


func _set_size(ctrl: Control, raw: float, lo: int, hi: int) -> void:
	if ctrl:
		ctrl.add_theme_font_size_override("font_size", clamp(int(round(raw)), lo, hi))


func show_screen(level: int, stars: int, streak: int) -> void:
	visible = true
	if level_label:
		level_label.text = "Level %d" % level
	if stars_label:
		stars_label.text = "★ %d" % stars
	if streak_label:
		streak_label.text = "Best streak: x %d" % streak

	# Animate in
	if panel:
		panel.modulate.a = 0.0
		panel.scale = Vector2(0.8, 0.8)
		var tween := create_tween().set_parallel(true)
		tween.tween_property(panel, "modulate:a", 1.0, 0.3)
		tween.tween_property(panel, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT)


func hide_screen() -> void:
	visible = false


func _on_retry_pressed() -> void:
	retry_pressed.emit()


func _on_reset_pressed() -> void:
	reset_progress_pressed.emit()
