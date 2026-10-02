extends SceneTree

# Run with a rendering driver. Captures the compact game-over screen.
func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.get_node("Hud/HudScale/GameOver").visible = true
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png("res://.godot/game_over_preview.png")
	assert(result == OK, "Failed to save game-over preview")
	print("Game-over preview captured.")
	quit()
