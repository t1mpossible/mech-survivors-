extends SceneTree

var hits: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var weapon := load("res://scenes/orbit_weapon.tscn").instantiate() as OrbitWeapon
	root.add_child(weapon)
	weapon.damage_requested.connect(func(enemy, amount, name): hits.append({"enemy": enemy, "amount": amount, "name": name}))
	weapon.unlock()
	assert(weapon.level == 1 and weapon.count() == 2 and weapon.damage() == 32)
	assert(is_equal_approx(weapon.base_rotation_speed, 5.36 * 0.65))
	assert(weapon.choose_branch("shuriken") and not weapon.choose_branch("heat"))
	var damage := [32, 41, 41, 41, 45, 55, 49]
	var radii := [46.0, 46.0, 46.0, 55.2, 60.72, 60.72, 60.72]
	var counts := [2, 2, 2, 3, 3, 3, 4]
	for current_level in range(2, 8):
		assert(weapon.level == current_level)
		assert(weapon.damage() == damage[current_level - 1])
		assert(is_equal_approx(weapon.radius(), radii[current_level - 1]))
		assert(weapon.count() == counts[current_level - 1])
		assert(weapon.angles().size() == counts[current_level - 1])
		if current_level < 7:
			assert(weapon.upgrade())
	assert(not weapon.upgrade())
	weapon.reset()
	weapon.unlock()
	assert(weapon.choose_branch("heat") and not weapon.choose_branch("shuriken"))
	for current_level in range(2, 8):
		assert(weapon.count() == 0)
		assert(is_equal_approx(weapon.radius(), [80.0, 80.0, 80.0, 96.0, 96.0, 115.2, 115.2][current_level - 1]))
		assert(weapon.damage() == [0, 8, 10, 10, 10, 12, 12][current_level - 1])
		if current_level < 7:
			assert(weapon.upgrade())
	var inside := _enemy(Vector2(10, 0))
	var fire_image := AlienScout.THERMAL_FIRE.get_image()
	assert(fire_image != null and fire_image.get_width() == fire_image.get_height() * 3)
	assert(fire_image.get_width() <= 768, "Runtime atlas must use the lightweight import")
	assert(fire_image.get_pixel(0, 0).a == 0.0, "Fire atlas must have real transparency")
	var fire_offset := float(inside.get_instance_id() % 29) * 0.19
	for frame in range(4):
		inside.set_thermal_visual(true, (float(frame) + 0.1) / AlienScout.THERMAL_FIRE_FPS - fire_offset)
		assert(inside.thermal_fire_frame == frame % 3)
	inside.set_thermal_visual(false, 0.0)
	var second := _enemy(Vector2(0, 50))
	var wave_only := _enemy(Vector2(140, 0))
	var outside := _enemy(Vector2(160, 0))
	weapon.tick(0.01, Vector2.ZERO)
	assert(hits.size() == 2 and hits[0].amount == 12 and hits[1].amount == 12)
	assert(hits.all(func(hit): return hit.enemy == inside or hit.enemy == second))
	hits.clear()
	weapon.tick(0.38, Vector2.ZERO)
	assert(hits.is_empty())
	weapon.tick(0.02, Vector2.ZERO)
	assert(hits.size() == 2)
	hits.clear()
	weapon.tick(2.6, Vector2.ZERO)
	var wave_hits := hits.filter(func(hit): return hit.amount == 45)
	assert(wave_hits.size() == 3)
	assert(wave_hits.any(func(hit): return hit.enemy == wave_only))
	assert(not hits.any(func(hit): return hit.enemy == outside))
	assert(weapon.wave_visual_time > 0.0)
	assert(hits.all(func(hit): return hit.name == "ТЕРМОБАРИЧЕСКИЙ НАГРЕВ"))
	weapon.reset()
	hits.clear()
	weapon.tick(10.0, Vector2.ZERO)
	assert(hits.is_empty() and weapon.wave_visual_time == 0.0)
	# Both choices are offered at level 2, and the selected branch stays locked.
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.autocannon.apply_upgrade("fan")
	game.orbit_weapon.unlock()
	game._sync_orbit_weapon()
	game._open_upgrade_choice()
	assert(game.available_upgrades[0].kind == "orbit_branch_shuriken")
	assert(game.available_upgrades[1].kind == "orbit_branch_heat")
	game._choose_upgrade(1)
	assert(game.orbit_weapon.branch == "heat" and game.orbit_weapon.level == 2)
	assert(not paused)
	game.mech_position = Vector2.ZERO
	var previous_health := inside.health
	game._update_enemy_heat_visual(inside)
	game._update_enemy_heat_visual(outside)
	assert(inside.thermal_active and not outside.thermal_active)
	assert(inside.health == previous_health, "Burn visuals must not add damage")
	game.mech_position = Vector2(500, 0)
	game._update_enemy_heat_visual(inside)
	assert(not inside.thermal_active, "Flames must stop after leaving the aura")
	game.mech_position = Vector2.ZERO
	game._update_enemy_heat_visual(inside)
	game.orbit_weapon.reset()
	game._update_enemy_heat_visual(inside)
	assert(not inside.thermal_active, "Flames must stop when the weapon is disabled")
	game.orbit_weapon.unlock()
	game.orbit_weapon.choose_branch("heat")
	for step in range(5):
		game.orbit_weapon.upgrade()
	game._sync_orbit_weapon()
	assert(game.orbit_weapon.level == 7 and game.shuriken_unlocked)
	game.queue_free()
	weapon.queue_free()
	for enemy in [inside, second, wave_only, outside]:
		enemy.queue_free()
	await process_frame
	print("PASS: orbit branches, all level stats, area damage, wave, reset and upgrade choices")
	quit()


func _enemy(location: Vector2) -> AlienScout:
	var enemy := AlienScout.new()
	root.add_child(enemy)
	enemy.position = location
	enemy.set_process(false)
	return enemy
