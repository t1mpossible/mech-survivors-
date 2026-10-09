extends SceneTree


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var game: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.manual_paused = true
	game._position_camera()
	game.spawn_combat_effect(Vector2(710.0, 420.0), CombatEffect.Type.ROCKET_EXPLOSION, 0.62)
	game.spawn_combat_effect(Vector2(830.0, 420.0), CombatEffect.Type.ROCKET_EXPLOSION, 1.70)
	game.spawn_combat_effect(Vector2(950.0, 420.0), CombatEffect.Type.ENEMY_DEATH, 1.0)
	game.spawn_combat_effect(Vector2(1070.0, 420.0), CombatEffect.Type.ENEMY_DISSOLVE, 1.0)
	for effect_index in range(4):
		game.combat_effect_pool[effect_index].set_process(false)
	var shell := load("res://scenes/enemy_rocket.tscn").instantiate() as EnemyRocket
	game.add_child(shell)
	shell.activate(Vector2(700.0, 520.0), Vector2.RIGHT, 0.0, 0.0, 0.0, 4.0, Vector2.ONE, EnemyRocket.ProjectileKind.TURRET_SHELL)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("res://.godot/rocket_impact_preview.png")
	print("Rocket impact preview captured.")
	quit()
