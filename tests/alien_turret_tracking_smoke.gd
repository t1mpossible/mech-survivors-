extends SceneTree


class TurretGameStub extends Node2D:
	var shell: EnemyRocket

	func acquire_enemy_rocket() -> EnemyRocket:
		return shell


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := TurretGameStub.new()
	root.add_child(game)
	var shell := load("res://scenes/enemy_rocket.tscn").instantiate() as EnemyRocket
	game.add_child(shell)
	game.shell = shell
	var turret := load("res://scenes/alien_turret.tscn").instantiate() as AlienTurret
	game.add_child(turret)
	await process_frame
	turret.global_position = Vector2(100.0, 100.0)
	turret.set_process(false)
	shell.set_process(false)
	# Check the actual painted landmarks, including a scaled/rotated parent.
	for parent_angle: float in [0.0, 0.37]:
		game.rotation = parent_angle
		game.scale = Vector2.ONE * 1.25
		for i in range(8):
			var angle := i * TAU / 8.0
			turret.target_position = turret.to_global(turret.TURRET_PIVOT + Vector2.from_angle(angle) * 200.0)
			turret.gun_angle = angle
			turret.gun_angle_initialized = true
			turret.cooldown = 0.0
			turret._process(0.016)
			var gun_rect := turret._gun_draw_rect()
			var base_rect := turret._base_draw_rect()
			var gun_transform := Transform2D(turret.gun_angle, turret.TURRET_PIVOT)
			var attachment := gun_transform * (gun_rect.position + gun_rect.size * turret.GUN_PIVOT_UV)
			var fixed_attachment := base_rect.position + base_rect.size * turret.BASE_PIVOT_UV
			assert(attachment.is_equal_approx(fixed_attachment), "Attachment drifts while turning")
			var painted_muzzle := turret.to_global(gun_transform * (gun_rect.position + gun_rect.size * turret.GUN_MUZZLE_UV))
			assert(shell.active and shell.global_position.distance_to(painted_muzzle) < 0.001, "Shot misses painted muzzle")
			var expected_direction := game.global_transform.basis_xform(Vector2.from_angle(angle)).normalized()
			assert(shell.direction.distance_to(expected_direction) < 0.001)
			assert(turret.scale.is_equal_approx(turret.base_visual_scale), "Stationary mount wobbles")
	# Crossing -180/180 must take the short route without a full revolution.
	turret.gun_angle = deg_to_rad(179.0)
	turret.target_position = turret.to_global(turret.TURRET_PIVOT + Vector2.from_angle(deg_to_rad(-179.0)) * 200.0)
	turret._process(0.02)
	assert(turret._turret_direction().distance_to(Vector2.from_angle(deg_to_rad(-179.0))) < 0.001)
	print("PASS: painted hinge stays fixed at 8 angles; shots match painted muzzle; no scale wobble or wrap jump")
	quit()
