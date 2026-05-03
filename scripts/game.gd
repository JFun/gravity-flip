## Main game manager.
## Handles level loading, scoring, and game state transitions.
extends Node2D

# -- Config --
@export var starting_level: int = 1
@export var scroll_speed_increment: float = 5.0  ## Speed increase per level

const SAVE_PATH := "user://progress.cfg"

# -- State --
var current_level: int = 1
var total_score: int = 0
var is_paused: bool = false
var _is_transitioning: bool = false

# -- Transition overlay (built at runtime) --
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _level_label: Label

# -- Nodes --
@onready var player: CharacterBody2D = $Player
@onready var level_container: Node2D = $LevelContainer
@onready var hud: CanvasLayer = $HUD
@onready var death_screen: CanvasLayer = $DeathScreen
@onready var level_clear_screen: CanvasLayer = $LevelClearScreen
@onready var floor_body: StaticBody2D = $Floor
@onready var ceiling_body: StaticBody2D = $Ceiling


func _ready() -> void:
	# Connect player signals
	player.died.connect(_on_player_died)
	player.star_collected.connect(_on_star_collected)
	player.streak_changed.connect(_on_streak_changed)
	player.flipped.connect(_on_player_flipped)

	# Connect UI signals
	death_screen.retry_pressed.connect(_on_retry)
	death_screen.visible = false
	death_screen.hide_screen()

	level_clear_screen.continue_pressed.connect(_on_continue_to_next_level)
	level_clear_screen.hide_screen()

	if death_screen.has_signal("reset_progress_pressed"):
		death_screen.reset_progress_pressed.connect(_on_reset_progress_requested)

	_build_transition_overlay()

	# Start — restore saved progress if any.
	current_level = max(starting_level, _load_progress())
	_load_level(current_level)
	_update_hud()


func _load_progress() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return 1
	return int(cfg.get_value("progress", "current_level", 1))


func _save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "current_level", current_level)
	cfg.save(SAVE_PATH)


func _on_reset_progress_requested() -> void:
	if _is_transitioning:
		return
	current_level = 1
	_save_progress()
	death_screen.hide_screen()
	level_clear_screen.hide_screen()
	_load_level(current_level)
	_update_hud()


func _build_transition_overlay() -> void:
	## A black fade rect + centered "Level N" label, layered above the HUD.
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 30
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade_rect)

	_level_label = Label.new()
	_level_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_level_label.add_theme_font_size_override("font_size", 96)
	_level_label.modulate.a = 0.0
	_level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_level_label)


func _load_level(level_num: int) -> void:
	# Clear existing obstacles
	for child in level_container.get_children():
		child.queue_free()

	# Generate level from data
	var level_data := LevelData.get_level(level_num)
	_build_level(level_data)

	# Adjust scroll speed based on level
	player.scroll_speed = 250.0 + (level_num - 1) * scroll_speed_increment

	# Reset player
	player.reset(Vector2(100, 400))


func _build_level(data: Dictionary) -> void:
	var x_offset := 400.0  # Start obstacles after a runway

	for obstacle_def in data.get("obstacles", []):
		var obstacle := _create_obstacle(obstacle_def)
		if obstacle:
			obstacle.position.x = x_offset + obstacle_def.get("x", 0.0)
			obstacle.position.y = obstacle_def.get("y", 0.0)
			level_container.add_child(obstacle)

	# Place stars
	for star_def in data.get("stars", []):
		var star := _create_star()
		star.position = Vector2(
			x_offset + star_def.get("x", 0.0),
			star_def.get("y", 0.0)
		)
		level_container.add_child(star)

	# Level end trigger — must span the whole corridor vertically, otherwise
	# the ball can pass under/over it and the level never advances.
	var end_trigger := Area2D.new()
	var end_shape := CollisionShape2D.new()
	var end_rect := RectangleShape2D.new()
	end_rect.size = Vector2(40, 2000)
	end_shape.shape = end_rect
	end_trigger.add_child(end_shape)
	end_trigger.position = Vector2(x_offset + data.get("length", 2000.0), 400.0)
	end_trigger.collision_layer = 0
	end_trigger.collision_mask = 2  # Player layer
	end_trigger.body_entered.connect(_on_level_end_reached)
	end_trigger.add_to_group("level_end")
	level_container.add_child(end_trigger)


func _create_obstacle(def: Dictionary) -> Node2D:
	var kind: String = def.get("type", "wall")

	match kind:
		"wall":
			return _make_wall(
				def.get("gap_y", 400.0),
				def.get("gap_size", 180.0)
			)
		"spike_floor":
			return _make_spike(true)
		"spike_ceiling":
			return _make_spike(false)
		_:
			return null


func _make_wall(gap_y: float, gap_size: float) -> Node2D:
	## Creates a wall with a gap. Two StaticBody2D rects with a gap between them.
	var wall_node := Node2D.new()
	wall_node.add_to_group("obstacle")

	var corridor_top := 80.0    # Y of ceiling
	var corridor_bottom := 720.0  # Y of floor

	# Top portion (from ceiling to gap top)
	var top_height: float = gap_y - gap_size / 2.0 - corridor_top
	if top_height > 5.0:
		var top_body := StaticBody2D.new()
		top_body.add_to_group("obstacle")
		top_body.collision_layer = 1  # environment layer — player slides on walls
		var top_shape := CollisionShape2D.new()
		var top_rect := RectangleShape2D.new()
		top_rect.size = Vector2(30, top_height)
		top_shape.shape = top_rect
		top_body.add_child(top_shape)
		top_body.position.y = corridor_top + top_height / 2.0

		# Visual
		var top_visual := ColorRect.new()
		top_visual.size = Vector2(30, top_height)
		top_visual.position = Vector2(-15, -top_height / 2.0)
		top_visual.color = Color(0.35, 0.55, 0.7, 0.9)
		top_body.add_child(top_visual)

		wall_node.add_child(top_body)

	# Bottom portion (from gap bottom to floor)
	var bottom_start: float = gap_y + gap_size / 2.0
	var bottom_height: float = corridor_bottom - bottom_start
	if bottom_height > 5.0:
		var bottom_body := StaticBody2D.new()
		bottom_body.add_to_group("obstacle")
		bottom_body.collision_layer = 1  # environment layer
		var bottom_shape := CollisionShape2D.new()
		var bottom_rect := RectangleShape2D.new()
		bottom_rect.size = Vector2(30, bottom_height)
		bottom_shape.shape = bottom_rect
		bottom_body.add_child(bottom_shape)
		bottom_body.position.y = bottom_start + bottom_height / 2.0

		var bottom_visual := ColorRect.new()
		bottom_visual.size = Vector2(30, bottom_height)
		bottom_visual.position = Vector2(-15, -bottom_height / 2.0)
		bottom_visual.color = Color(0.35, 0.55, 0.7, 0.9)
		bottom_body.add_child(bottom_visual)

		wall_node.add_child(bottom_body)

	return wall_node


func _make_spike(on_floor: bool) -> Node2D:
	## Creates a spike hazard on the floor or ceiling.
	var spike := StaticBody2D.new()
	spike.add_to_group("hazard")
	spike.collision_layer = 16  # hazard layer (bit 5 = 2^4 = 16)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, 20)
	shape.shape = rect
	spike.add_child(shape)

	# Visual — triangle-ish colored rect (replace with polygon later)
	var visual := ColorRect.new()
	visual.size = Vector2(40, 20)
	visual.position = Vector2(-20, -10)
	visual.color = Color(0.9, 0.25, 0.25)
	spike.add_child(visual)

	if on_floor:
		spike.position.y = 710  # Just above floor
	else:
		spike.position.y = 90   # Just below ceiling

	return spike


func _create_star() -> Area2D:
	var star := Area2D.new()
	star.add_to_group("star")
	star.collision_layer = 4  # collectibles
	star.collision_mask = 2   # detect player

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 25.0
	shape.shape = circle
	star.add_child(shape)

	# Visual — a real 5-pointed star polygon, not a square. The HUD shows
	# "★ N", so the in-game pickup needs to look like a star too.
	var visual := Polygon2D.new()
	visual.polygon = _star_polygon(22.0, 9.0)
	visual.color = Color(1.0, 0.85, 0.2)
	star.add_child(visual)

	star.body_entered.connect(func(body):
		if body == player:
			player.collect_star()
			star.queue_free()
	)

	return star


## Returns a 5-pointed star polygon with the given outer / inner radii,
## centered on the origin and pointing up.
func _star_polygon(outer_r: float, inner_r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var points := 5
	for i in points * 2:
		var r: float = outer_r if i % 2 == 0 else inner_r
		# Start at the top (-PI/2) and step around in 10 increments.
		var angle: float = -PI / 2.0 + i * PI / points
		pts.append(Vector2(cos(angle) * r, sin(angle) * r))
	return pts


# -- Signal handlers --
func _on_player_died() -> void:
	death_screen.show_screen(
		current_level,
		player.stars_collected,
		player.flip_streak
	)


func _on_star_collected(count: int) -> void:
	_update_hud()


func _on_streak_changed(streak: int) -> void:
	_update_hud()


func _on_player_flipped(_dir: float) -> void:
	pass  # Hook for future flip-based effects


func _on_level_end_reached(body: Node2D) -> void:
	if body == player and not _is_transitioning:
		_transition_to_next_level()


func _transition_to_next_level() -> void:
	_is_transitioning = true
	# Freeze the ball mid-air so it doesn't visibly snap back.
	player.is_alive = false
	player.velocity = Vector2.ZERO

	AudioManager.play("level_clear")

	# Show the level-clear panel and wait for the player to tap continue.
	level_clear_screen.show_screen(
		current_level,
		current_level + 1,
		player.stars_collected,
		player.flip_streak,
	)


func _on_continue_to_next_level() -> void:
	level_clear_screen.hide_screen()

	current_level += 1
	_save_progress()
	_level_label.text = "Level %d" % current_level

	# Fade to black + slide in level label.
	var fade_in := create_tween().set_parallel(true)
	fade_in.tween_property(_fade_rect, "color:a", 1.0, 0.25)
	fade_in.tween_property(_level_label, "modulate:a", 1.0, 0.25)
	await fade_in.finished

	# Swap level under cover of black.
	_load_level(current_level)
	_update_hud()

	# Hold the banner briefly so the player reads it.
	await get_tree().create_timer(0.35).timeout

	# Fade back in, then drop the banner.
	var fade_out := create_tween().set_parallel(true)
	fade_out.tween_property(_fade_rect, "color:a", 0.0, 0.3)
	fade_out.tween_property(_level_label, "modulate:a", 0.0, 0.3)
	await fade_out.finished

	_is_transitioning = false


func _on_retry() -> void:
	death_screen.hide_screen()
	_load_level(current_level)
	_update_hud()


func _update_hud() -> void:
	if hud.has_method("update_display"):
		hud.update_display(
			current_level,
			player.stars_collected,
			player.flip_streak
		)
