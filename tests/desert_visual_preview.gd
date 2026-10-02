extends SceneTree

# Run with a rendering driver (not --headless). Captures the real scene and HUD.
func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.initial_scout.position = Vector2(885, 485)
	game.initial_scout.set_process(false)
	var enemy_scenes := ["alien_brute", "alien_turret", "alien_bomber"]
	var locations := [Vector2(670, 370), Vector2(965, 355), Vector2(720, 540)]
	for index in range(enemy_scenes.size()):
		var enemy = load("res://scenes/%s.tscn" % enemy_scenes[index]).instantiate()
		game.add_child(enemy)
		enemy.position = locations[index]
		enemy.target_position = game.mech_position
		enemy.set_process(false)
	game._position_camera()
	await _capture("desert_battle_preview")
	game.mech_position = Vector2(35, 35)
	game.mech_sprite.position = game.mech_position
	game._position_camera()
	await _capture("desert_edge_preview")
	game.queue_free()
	await process_frame
	var arena = load("res://scenes/test_arena.tscn").instantiate()
	root.add_child(arena)
	arena.set_process(false)
	arena.mech_position = Vector2(800, 440)
	arena.mech_sprite.position = arena.mech_position
	arena._position_camera()
	await _capture("desert_arena_preview")
	print("Desert battle, edge and arena previews captured.")
	quit()


func _capture(filename: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png("res://.godot/%s.png" % filename)
	assert(result == OK, "Failed to save terrain preview")
