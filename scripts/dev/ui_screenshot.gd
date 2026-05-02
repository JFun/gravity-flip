## Dev-only: open game.tscn, force level-clear or game-over panel, screenshot, quit.
## Run with: godot --path . scripts/dev/ui_screenshot.gd -- <portrait|landscape> <clear|over>
extends SceneTree


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var orient := args[0] if args.size() > 0 else "portrait"
	var which := args[1] if args.size() > 1 else "clear"

	var w := 720 if orient == "portrait" else 1560
	var h := 1280 if orient == "portrait" else 720
	DisplayServer.window_set_size(Vector2i(w, h))

	var scene := load("res://scenes/game.tscn") as PackedScene
	var root := scene.instantiate()
	get_root().add_child(root)

	await process_frame
	await create_timer(0.3).timeout

	if which == "clear":
		var s = root.get_node("LevelClearScreen")
		s.show_screen(2, 3, 1, 8)
	elif which == "play":
		# Just gameplay — no panel.
		pass
	else:
		var s = root.get_node("DeathScreen")
		s.show_screen(2, 1, 4)

	await create_timer(0.5).timeout

	var img := get_root().get_viewport().get_texture().get_image()
	var path := "user://ui_%s_%s.png" % [orient, which]
	img.save_png(path)
	print("saved ", ProjectSettings.globalize_path(path))
	quit()
