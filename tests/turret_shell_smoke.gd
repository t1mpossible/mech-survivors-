extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var shell := load("res://scenes/enemy_rocket.tscn").instantiate() as EnemyRocket
	root.add_child(shell)
	await process_frame
	shell.activate(Vector2.ZERO, Vector2.RIGHT, 90.0, 18.0, 0.5, 4.0, Vector2.ONE, EnemyRocket.ProjectileKind.TURRET_SHELL)
	assert(shell.active)
	assert(shell.projectile_kind == EnemyRocket.ProjectileKind.TURRET_SHELL)
	assert(EnemyRocket.TURRET_SHELL_ART != null)
	assert(EnemyRocket.TURRET_SHELL_TRAIL != null)
	assert(is_equal_approx(float(EnemyRocket.TURRET_SHELL_TRAIL.get_width()) / float(EnemyRocket.TURRET_SHELL_TRAIL.get_height()), 3.0))
	shell.visual_time = 0.2
	shell.queue_redraw()
	shell.deactivate()
	print("PASS: turret projectile uses the tank shell visual type")
	quit()
