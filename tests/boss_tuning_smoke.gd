extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Variant = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.initial_scout.set_process(false)
	var bomber := load("res://scenes/alien_bomber.tscn").instantiate() as AlienBomber
	bomber.position = Vector2(100, 100)
	bomber.target_position = Vector2(500, 500)
	game.add_child(bomber)
	await process_frame
	assert(is_equal_approx(bomber.movement_speed, 20.25), "Walking mine speed should be +35%")
	bomber.queue_free()
	game._spawn_boss()
	var boss: AlienBoss = game.boss
	boss.set_process(false)
	assert(is_equal_approx(boss.BOSS_ROCKET_SPEED, 51.84))
	assert(is_equal_approx(boss.ROCKET_INTERVAL_PHASE_ONE, 2.55))
	assert(is_equal_approx(boss.MINE_PROJECTILE_SPEED, 75.0))
	assert(is_equal_approx(boss.MINE_PROJECTILE_FLIGHT_TIME, 3.0))
	var hud: Control = game.get_node("Hud/HudScale")
	assert(hud.get_node("BossHealth").visible and hud.get_node("BossPhase").visible)
	assert(hud.get_node("BossHealth").get_rect().position.y < hud.get_node("WaveTimer").get_rect().position.y)
	assert(hud.get_node("BossPhase").text == "БОСС • ФАЗА 1 / 3")
	assert(not hud.get_node("Wave1").visible, "Debug wave buttons must not overlap boss HUD")
	boss.health = 850
	boss.take_damage(0)
	assert(is_equal_approx(hud.get_node("BossHealth").value, 850.0))
	boss.take_damage(850)
	assert(boss.phase == 2 and is_equal_approx(hud.get_node("BossHealth").value, 2000.0))
	assert(hud.get_node("BossPhase").text == "БОСС • ФАЗА 2 / 3")
	boss.mine_time_left = 0.01
	boss._process(0.02)
	var mines := get_nodes_in_group("enemy_hazards")
	assert(mines.size() == 2)
	for mine in mines:
		assert(is_equal_approx(mine.speed, 75.0))
		assert(is_equal_approx(mine.fall_time, 3.0))
	boss._process(0.29)
	assert(get_nodes_in_group("enemy_hazards").size() == 2, "Second pair must wait for the 0.3-second burst delay")
	boss._process(0.02)
	assert(get_nodes_in_group("enemy_hazards").size() == 4, "Phase two salvo must launch four shells as two pairs")
	boss.phase = 1
	boss.rocket_time_left = 0.01
	boss.target_position = Vector2(800, 300)
	boss._process(0.02)
	assert(is_equal_approx(boss.rocket_time_left, 2.55))
	var active_rockets: Array = game.enemy_rocket_pool.filter(func(rocket: EnemyRocket) -> bool: return rocket.active)
	assert(active_rockets.size() == 2)
	for rocket in active_rockets:
		assert(is_equal_approx(rocket.speed, 51.84))
	for rocket in active_rockets:
		rocket.deactivate()
	boss.phase = 2
	boss.health = 1
	boss.take_damage(1)
	assert(boss.phase == 3 and boss.max_health == 2660 and boss.health == 2660)
	assert(is_equal_approx(hud.get_node("BossHealth").max_value, 2660.0))
	assert(is_equal_approx(hud.get_node("BossHealth").value, 2660.0))
	boss._launch_rocket_pair()
	active_rockets = game.enemy_rocket_pool.filter(func(rocket: EnemyRocket) -> bool: return rocket.active)
	assert(active_rockets.size() == 2)
	for rocket in active_rockets:
		assert(is_equal_approx(rocket.speed, 51.84))
	boss.mine_time_left = 0.01
	boss._process(0.02)
	assert(get_nodes_in_group("enemy_hazards").size() == 6, "Phase three first mine pair must launch")
	boss._process(0.29)
	assert(get_nodes_in_group("enemy_hazards").size() == 6)
	boss._process(0.02)
	assert(get_nodes_in_group("enemy_hazards").size() == 8, "Phase three salvo must also launch four shells")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/boss_hud_preview.png")
	game.queue_free()
	await process_frame
	print("PASS: walking mine speed, boss phase attacks, split timing and HUD")
	quit()
