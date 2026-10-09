extends SceneTree

# Run with a rendering driver (not --headless). Captures the actual upgrade layout.
func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game._open_upgrade_choice()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png("res://.godot/upgrade_menu_preview.png")
	assert(result == OK, "Failed to save upgrade menu preview")
	paused = false
	print("Upgrade menu preview captured.")
	quit()
