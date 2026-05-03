## Title screen — game's front door.
## Shows the title, a tap-to-play hint, the mute button, and a Reset Progress
## affordance with two-tap confirmation. Tapping anywhere on the screen (other
## than the buttons) starts the game by loading game.tscn.
extends Control

const GAME_SCENE: String = "res://scenes/game.tscn"
const SAVE_PATH: String = "user://progress.cfg"
const RESET_CONFIRM_WINDOW: float = 3.0  ## Seconds the "tap again" prompt stays armed.

const REFERENCE_SHORT_SIDE: float = 1080.0
const TITLE_REF_SIZE: float = 96.0
const HINT_REF_SIZE: float = 48.0
const CONTINUE_REF_SIZE: float = 40.0
const RESET_REF_SIZE: float = 32.0
const MUTE_REF_SIZE: float = 80.0

@onready var title_label: Label = $TitleLabel
@onready var hint_label: Label = $HintLabel
@onready var continue_label: Label = $ContinueLabel
@onready var ball_anim: TextureRect = $BallSlot/BallAnim
@onready var mute_button: Button = $MuteButton
@onready var reset_button: Button = $ResetButton

var _ball_base_y: float = 0.0

var _reset_armed: bool = false
var _reset_disarm_timer: SceneTreeTimer


func _ready() -> void:
	_generate_ball_texture()
	_animate_ball()

	get_viewport().size_changed.connect(_apply_layout)
	_apply_layout()

	# Tap anywhere on the background → start the game. _unhandled_input fires
	# only after Buttons' built-in handlers consume their own clicks, so taps
	# on Mute / Reset don't accidentally start the game.

	# Mute button reuses mute_button.gd; sync its state with AudioManager.
	if mute_button:
		mute_button.pressed.connect(AudioManager.toggle_mute)
		AudioManager.mute_changed.connect(_refresh_mute)
		_refresh_mute(AudioManager.muted)

	# Reset progress: two-tap confirmation.
	if reset_button:
		reset_button.pressed.connect(_on_reset_pressed)

	_refresh_continue_label()


func _refresh_mute(muted: bool) -> void:
	if mute_button and "muted" in mute_button:
		mute_button.muted = muted


# -- Layout / fonts (responsive across orientations) ---------------------------
func _apply_layout() -> void:
	var size := get_viewport().get_visible_rect().size
	var scale: float = min(size.x, size.y) / REFERENCE_SHORT_SIDE
	_set_font_size(title_label, TITLE_REF_SIZE * scale, 48, 132)
	_set_font_size(hint_label, HINT_REF_SIZE * scale, 24, 72)
	_set_font_size(continue_label, CONTINUE_REF_SIZE * scale, 22, 56)
	_set_font_size(reset_button, RESET_REF_SIZE * scale, 18, 44)
	_set_font_size(mute_button, MUTE_REF_SIZE * scale, 36, 96)


func _set_font_size(ctrl: Control, raw: float, lo: int, hi: int) -> void:
	if ctrl:
		ctrl.add_theme_font_size_override("font_size", clampi(int(round(raw)), lo, hi))


# -- Continue label ("Level N" if you have saved progress) ---------------------
func _refresh_continue_label() -> void:
	if not continue_label:
		return
	var saved := _load_saved_level()
	if saved > 1:
		continue_label.text = "Continue from Level %d" % saved
		continue_label.visible = true
	else:
		continue_label.visible = false


func _load_saved_level() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return 1
	return int(cfg.get_value("progress", "current_level", 1))


# -- Background tap → start game -----------------------------------------------
## Only handle the synthetic mouse event, not raw touch. On iOS a tap fires
## *both* — but Buttons only consume the mouse event (that's how they trigger
## `pressed`). If we reacted to the raw touch here, taps on Mute/Reset would
## start the game before the button's own handler ran.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_start_game()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_start_game()


func _start_game() -> void:
	Analytics.log_event("title_play", {
		"saved_level": _load_saved_level(),
	})
	get_tree().change_scene_to_file(GAME_SCENE)


# -- Reset progress (two-tap confirmation) -------------------------------------
func _on_reset_pressed() -> void:
	if not _reset_armed:
		_reset_armed = true
		reset_button.text = "Tap again to confirm reset"
		_reset_disarm_timer = get_tree().create_timer(RESET_CONFIRM_WINDOW)
		_reset_disarm_timer.timeout.connect(_disarm_reset)
		return
	# Confirmed — overwrite save with current_level=1 and refresh UI.
	_disarm_reset()
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "current_level", 1)
	cfg.save(SAVE_PATH)
	_refresh_continue_label()


func _disarm_reset() -> void:
	_reset_armed = false
	if reset_button:
		reset_button.text = "Reset progress"


# -- Cosmetic ball animation ---------------------------------------------------
func _animate_ball() -> void:
	if not ball_anim:
		return
	# Drive a true sine wave via tween_method instead of chaining property
	# tweens — chained tweens with a 0-duration "reset" snap caused a visible
	# 22px jump per cycle. tween_method updates the ball position every frame
	# from sin(t), giving a continuous, seamless loop.
	await get_tree().process_frame
	_ball_base_y = ball_anim.position.y
	var tween := create_tween().set_loops()
	tween.tween_method(_set_ball_offset, 0.0, TAU, 2.8)


func _set_ball_offset(t: float) -> void:
	if ball_anim:
		ball_anim.position.y = _ball_base_y + sin(t) * 22.0


func _generate_ball_texture() -> void:
	## Same procedural glowing-ball as the player, so the title screen reads
	## as part of the same game. Larger source size since the title-screen
	## ball renders bigger than the in-game ball.
	if not ball_anim:
		return
	var size := 128
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size / 2.0, size / 2.0)
	var radius := size / 2.0
	for x in size:
		for y in size:
			var dist := Vector2(x, y).distance_to(center)
			if dist < radius - 2.0:
				var t := dist / (radius - 2.0)
				var r := lerpf(1.0, 0.4, t * t)
				var g := lerpf(1.0, 0.65, t * t)
				var b := lerpf(1.0, 0.95, t * t)
				img.set_pixel(x, y, Color(r, g, b, 1.0))
			elif dist < radius:
				var alpha := 1.0 - (dist - (radius - 2.0)) / 2.0
				img.set_pixel(x, y, Color(0.5, 0.75, 1.0, alpha))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	ball_anim.texture = ImageTexture.create_from_image(img)
