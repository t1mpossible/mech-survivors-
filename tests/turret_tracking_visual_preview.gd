extends SceneTree


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	if "--angles" in OS.get_cmdline_user_args():
		await _capture_angles()
		return
	var game := load("res://scenes/main.tscn").instantiate() as Node2D
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.manual_paused = true
	var turret := load("res://scenes/alien_turret.tscn").instantiate() as AlienTurret
	game.add_child(turret)
	turret.global_position = Vector2(690.0, 535.0)
	turret.target_position = game.mech_position
	turret.gun_angle = turret._desired_gun_angle()
	turret.gun_angle_initialized = true
	turret.set_process(false)
	turret.queue_redraw()
	var shell := load("res://scenes/enemy_rocket.tscn").instantiate() as EnemyRocket
	game.add_child(shell)
	var direction := turret._turret_direction()
	shell.activate(turret._muzzle_global_position(direction), direction, 0.0, 18.0, 0.0, 4.0, Vector2.ONE, EnemyRocket.ProjectileKind.TURRET_SHELL)
	shell.visual_time = 0.16
	shell.set_process(false)
	shell.queue_redraw()
	game._position_camera()
	await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("res://.godot/turret_tracking_preview.png")
	print("Turret tracking preview captured.")
	quit()


func _capture_angles() -> void:
	var background := ColorRect.new()
	background.color = Color("292d38")
	background.size = Vector2(2000, 1200)
	root.add_child(background)
	var stage := Node2D.new()
	root.add_child(stage)
	for i in range(8):
		var turret := load("res://scenes/alien_turret.tscn").instantiate() as AlienTurret
		stage.add_child(turret)
		turret.set_process(false)
		turret.position = Vector2(75 + (i % 4) * 160, 97 + (i / 4) * 165)
		turret.scale = Vector2.ONE * 1.25
		turret.gun_angle = i * TAU / 8.0
		turret.gun_angle_initialized = true
		turret.queue_redraw()
		var label := Label.new()
		label.text = "%d°" % (i * 45)
		label.position = turret.position + Vector2(-14, 61)
		label.add_theme_font_size_override("font_size", 12)
		stage.add_child(label)
		var shell := load("res://scenes/enemy_rocket.tscn").instantiate() as EnemyRocket
		stage.add_child(shell)
		var direction := turret._turret_direction()
		shell.activate(turret._muzzle_global_position() + direction * 18.0, direction, 0.0, 18.0, 0.0, 4.0, Vector2.ONE, EnemyRocket.ProjectileKind.TURRET_SHELL)
		shell.visual_time = 0.16
		shell.set_process(false)
		shell.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/turret_angles_preview.png")
	print("Captured all eight turret angles.")
	quit()
