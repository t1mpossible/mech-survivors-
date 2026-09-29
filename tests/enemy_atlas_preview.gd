extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1200, 700)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scenes := ["alien_turret", "alien_mortar", "alien_boss"]
	for row in range(2):
		for column in range(3):
			var enemy := load("res://scenes/%s.tscn" % scenes[column]).instantiate() as AlienScout
			viewport.add_child(enemy)
			enemy.set_process(false)
			enemy.scale = Vector2.ONE * 3.0
			enemy.position = Vector2(200 + column * 400, 180 + row * 350)
			enemy.movement_animation_active = row == 1
			enemy.visual_time = 0.25
			enemy.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://.godot/enemy_atlas_preview.png")
	quit()
