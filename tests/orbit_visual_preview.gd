extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var arena = load("res://scenes/test_arena.tscn").instantiate()
	root.add_child(arena)
	arena.set_process(false)
	arena.test_weapon_level = 7
	arena._equip_test_weapon("heat")
	arena.mech_position = Vector2(800, 350)
	arena.mech_sprite.position = arena.mech_position
	arena.weapon_visual_time = 1.0
	arena.orbit_weapon.wave_origin = arena.mech_position
	arena.orbit_weapon.wave_visual_time = 0.22
	arena._position_camera()
	for enemy in get_nodes_in_group("enemies"):
		arena._update_enemy_heat_visual(enemy as AlienScout)
	arena.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/thermal_preview.png")
	quit()
