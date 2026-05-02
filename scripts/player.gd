## Player controller for Gravity Flip.
## Handles gravity flipping, movement, collisions, and juice effects.
extends CharacterBody2D

# -- Signals --
signal died
signal flipped(gravity_dir: float)
signal star_collected(count: int)
signal streak_changed(streak: int)

# -- Movement --
@export var scroll_speed: float = 250.0
@export var gravity_strength: float = 520.0
@export var max_fall_speed: float = 520.0

# -- Flip feel --
@export var flip_rotation_time: float = 0.12
@export var flip_screen_shake: float = 3.0
@export var flip_cooldown: float = 0.0  ## 0 = no cooldown (enable later in Zone 4)
@export var flip_kick: float = 300.0  ## Instant velocity in the new gravity direction.

# -- State --
var gravity_dir: float = 1.0   # 1.0 = down, -1.0 = up
var is_alive: bool = true
var stars_collected: int = 0
var flip_streak: int = 0
var _can_flip: bool = true
var _time_since_last_collision: float = 999.0
var _total_distance: float = 0.0

# -- Nodes (assigned in _ready or via @onready) --
@onready var sprite: Sprite2D = $Sprite2D
@onready var trail: GPUParticles2D = get_node_or_null("Trail")
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var camera: Camera2D = $Camera2D


## Ball is shown at this fraction from the left of the viewport. Standard
## auto-scroller value (~0.3) gives the player a long visible runway ahead.
const BALL_LEFT_FRAC := 0.3


## Transient shake delta added on top of the computed left-anchor offset.
var _shake_offset: Vector2 = Vector2.ZERO

## Tween handles we may need to kill if the player resets while they're
## mid-flight (death fade-out, screen shake, etc.). Without killing them,
## a running tween will overwrite the values reset() just set and the ball
## stays invisible/tiny on the next level.
var _death_tween: Tween
var _shake_tween: Tween


func _ready() -> void:
	_setup_visuals()
	_generate_ball_texture()


## Computed every frame so it's robust to orientation changes, late viewport
## sizing on iOS, and any tween that mutates camera.offset directly.
func _update_camera_offset() -> void:
	if not camera:
		return
	var view_w: float = get_viewport().get_visible_rect().size.x
	if view_w <= 1.0:
		return
	var zoom: float = max(0.001, camera.zoom.x)
	var base_x := view_w * (0.5 - BALL_LEFT_FRAC) / zoom
	camera.offset = Vector2(base_x, 0) + _shake_offset


func _unhandled_input(event: InputEvent) -> void:
	if not is_alive:
		return

	# Accept touch, click, or spacebar.
	# NOTE: On iOS a single tap fires *both* an InputEventScreenTouch and an
	# emulated InputEventMouseButton (which also matches the "flip" action).
	# Handling both would flip gravity twice per tap (net zero). Prefer the
	# touch event when present and ignore the synthetic mouse button.
	var should_flip := false
	if event is InputEventScreenTouch:
		if event.pressed:
			should_flip = true
	elif event is InputEventMouseButton:
		# Only honor real mouse clicks (desktop). Synthetic ones from touch
		# emulation are flagged by Godot — but as a safe rule, just skip
		# mouse buttons here; the touch branch above already handled mobile.
		# On desktop we accept the spacebar / mouse via the action instead.
		pass
	elif event.is_action_pressed("flip"):
		should_flip = true

	if should_flip and _can_flip:
		_do_flip()
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# Apply gravity
	velocity.y += gravity_strength * gravity_dir * delta
	velocity.y = clampf(velocity.y, -max_fall_speed, max_fall_speed)

	# Auto-scroll right
	velocity.x = scroll_speed

	move_and_slide()

	# Lock camera vertical position to corridor center so the view doesn't
	# bob with the ball. Horizontal still follows the player.
	if camera:
		camera.global_position.y = 400.0

	_update_camera_offset()

	# Track distance
	_total_distance += scroll_speed * delta

	# Track collision timing for streak
	_time_since_last_collision += delta

	# Check if we hit a hazard (layer 5)
	var ramming_wall := false
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if collider.is_in_group("hazard"):
			_die()
			return
		elif collider.is_in_group("obstacle") and absf(col.get_normal().x) > 0.7:
			# Front-on collision with a wall = game over (sliding along
			# the top/bottom edge with a vertical normal is fine).
			ramming_wall = true
		else:
			# Hit floor/ceiling — reset fall velocity
			velocity.y = 0.0
			_time_since_last_collision = 0.0

	if ramming_wall:
		_die()
		return

	# Update trail color based on gravity direction
	_update_trail()


# -- Core flip mechanic --
func _do_flip() -> void:
	gravity_dir *= -1.0
	# Instant kick in the new gravity direction so the flip feels snappy.
	velocity.y = flip_kick * gravity_dir
	flip_streak += 1
	flipped.emit(gravity_dir)
	streak_changed.emit(flip_streak)
	AudioManager.play("flip")

	# Rotation tween (cosmetic)
	var tween := create_tween()
	tween.tween_property(
		sprite, "rotation",
		sprite.rotation + PI,
		flip_rotation_time
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Screen shake
	_shake_camera(flip_screen_shake, 0.08)

	# Haptic feedback (mobile)
	Input.vibrate_handheld(15)

	# Cooldown (for Zone 4+)
	if flip_cooldown > 0.0:
		_can_flip = false
		get_tree().create_timer(flip_cooldown).timeout.connect(
			func(): _can_flip = true
		)


# -- Death --
func _die() -> void:
	if not is_alive:
		return
	is_alive = false
	velocity = Vector2.ZERO

	# Death visual: scale down + fade. Stored so reset() can kill it if the
	# player retries / transitions before the tween finishes.
	if _death_tween and _death_tween.is_valid():
		_death_tween.kill()
	_death_tween = create_tween().set_parallel(true)
	_death_tween.tween_property(sprite, "scale", Vector2(0.1, 0.1), 0.3)
	_death_tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	if trail:
		trail.emitting = false

	# Shake hard
	_shake_camera(8.0, 0.2)

	# Haptic
	Input.vibrate_handheld(50)

	AudioManager.play("death")
	died.emit()


# -- Collectible handling (called by collectible's Area2D) --
func collect_star() -> void:
	stars_collected += 1
	star_collected.emit(stars_collected)
	_shake_camera(2.0, 0.05)
	AudioManager.play("star")


# -- Restart --
func reset(start_pos: Vector2) -> void:
	# Kill any in-flight tweens BEFORE we set sprite/camera state, so they
	# don't overwrite our reset values on subsequent frames.
	if _death_tween and _death_tween.is_valid():
		_death_tween.kill()
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()

	global_position = start_pos
	velocity = Vector2.ZERO
	gravity_dir = 1.0
	is_alive = true
	stars_collected = 0
	flip_streak = 0
	_total_distance = 0.0
	_can_flip = true
	sprite.scale = Vector2.ONE
	sprite.modulate = Color.WHITE
	sprite.rotation = 0.0
	_shake_offset = Vector2.ZERO
	if trail:
		trail.emitting = true
	# Snap the camera to the new position so position_smoothing doesn't leave
	# the ball off-screen for the first ~second after a level transition.
	if camera:
		camera.reset_smoothing()
		_update_camera_offset()


# -- Visual helpers --
func _setup_visuals() -> void:
	# Ball starts with a warm color
	sprite.modulate = Color(0.95, 0.95, 1.0)


func _update_trail() -> void:
	if not trail:
		return
	# Warm when falling down, cool when falling up
	if gravity_dir > 0:
		trail.modulate = Color(1.0, 0.6, 0.3, 0.8)  # warm orange
	else:
		trail.modulate = Color(0.3, 0.7, 1.0, 0.8)  # cool blue


func _shake_camera(intensity: float, duration: float) -> void:
	if not camera:
		return
	# Tween a separate _shake_offset; the per-frame camera offset update adds
	# this on top of the computed left-anchor base, so shake never resets the
	# anchor. Stored so reset() can kill it.
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	_shake_tween = create_tween()
	_shake_tween.tween_property(self, "_shake_offset",
		Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)),
		duration * 0.5)
	_shake_tween.tween_property(self, "_shake_offset", Vector2.ZERO, duration * 0.5)


func get_distance() -> float:
	return _total_distance


func _generate_ball_texture() -> void:
	## Creates a glowing circle sprite at runtime so the project needs zero external assets.
	var size := 64
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size / 2.0, size / 2.0)
	var radius := size / 2.0

	for x in size:
		for y in size:
			var dist := Vector2(x, y).distance_to(center)
			if dist < radius - 2.0:
				# Inner glow: bright white center fading to blue edge
				var t := dist / (radius - 2.0)
				var r := lerpf(1.0, 0.4, t * t)
				var g := lerpf(1.0, 0.65, t * t)
				var b := lerpf(1.0, 0.95, t * t)
				img.set_pixel(x, y, Color(r, g, b, 1.0))
			elif dist < radius:
				# Soft edge (anti-alias)
				var alpha := 1.0 - (dist - (radius - 2.0)) / 2.0
				img.set_pixel(x, y, Color(0.5, 0.75, 1.0, alpha))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))

	var tex := ImageTexture.create_from_image(img)
	sprite.texture = tex
	sprite.scale = Vector2(0.6, 0.6)  # Scale to match collision radius
