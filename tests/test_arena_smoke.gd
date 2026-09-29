extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var arena = load("res://scenes/test_arena.tscn").instantiate()
	root.add_child(arena)
	arena.set_process(false)
	await process_frame
	assert(arena.training_slots.size() == 8)
	assert(arena.move_speed == 144.0)
	assert(arena.level_down.size.x <= 16.0 and arena.level_down.size.y <= 9.0)
	assert(arena.level_up.size.x <= 16.0 and arena.level_up.size.y <= 9.0)
	assert(arena.dps_bar.size.y <= 4.0)
	assert(get_nodes_in_group("enemies").size() == 8)
	assert(not arena.autocannon.enabled and not arena.hunter_launcher.unlocked and not arena.laser.unlocked and not arena.shuriken_unlocked)
	for slot in arena.training_slots:
		assert(not slot.enemy.is_processing())
		assert(slot.enemy.movement_speed == 0.0)
		assert(slot.enemy.contact_damage_per_second == 0.0)
	arena._take_damage(1000.0)
	assert(arena.mech_health == arena.mech_max_health)
	arena._update_wave_progress(400.0)
	arena._update_wave_spawns(400.0)
	assert(arena.wave_number == 1 and arena.wave_elapsed == 0.0)
	# Every dead target returns at its own position, with full health, after two seconds.
	for index in range(arena.training_slots.size()):
		var enemy = arena.training_slots[index].enemy
		var location: Vector2 = enemy.position
		var kill_count := 3 if enemy is AlienBoss else 1
		for phase in range(kill_count):
			enemy.take_damage(enemy.max_health)
		assert(arena.training_slots[index].enemy == null)
		assert(not arena.victory_open)
		arena._update_training_respawns(1.99)
		assert(arena.training_slots[index].enemy == null)
		arena._update_training_respawns(0.02)
		var replacement = arena.training_slots[index].enemy
		assert(is_instance_valid(replacement))
		assert(replacement.position == location and replacement.health == replacement.max_health)
		assert(not replacement.is_processing())
		await process_frame
		assert(get_nodes_in_group("enemies").size() == 8)
	for key in arena.WEAPON_NAMES:
		for weapon_level in range(1, 8):
			arena.test_weapon_level = weapon_level
			arena._equip_test_weapon(key)
			var enabled_count := int(arena.autocannon.enabled) + int(arena.hunter_launcher.unlocked) + int(arena.laser.unlocked) + int(arena.shuriken_unlocked)
			assert(enabled_count == 1)
			if key in ["fan", "heavy"]:
				assert(arena.autocannon.level == weapon_level)
			elif key in ["swarm", "siege"]:
				assert(arena.hunter_launcher.level == weapon_level)
			elif key in ["burn", "pulse"]:
				assert(arena.laser.level == weapon_level)
			else:
				assert(arena.shuriken_level == weapon_level)
			assert(arena.plasma_round_pool.all(func(round): return not round.active))
			assert(arena.hunter_missile_pool.all(func(missile): return not missile.active))
	# The stand is a persistent pickup, and can be selected again after leaving it.
	arena.weapon_stands[0].player_position = arena.weapon_stands[0].global_position
	arena.weapon_stands[0]._process(0.01)
	assert(arena.selected_weapon == "fan")
	arena._equip_test_weapon("")
	assert(not arena.autocannon.enabled)
	assert(arena.weapon_stands.size() == 8)
	assert(not arena.hunter_launcher.unlocked and not arena.laser.unlocked and not arena.shuriken_unlocked)
	# DPS counts real damage (not overkill), expires after five gameplay seconds,
	# freezes during pause, and resets when changing the loadout.
	assert(arena.current_dps == 0.0 and arena.dps_bar.value == 0.0)
	var dps_target = arena.training_slots[0].enemy
	arena._deal_weapon_damage(dps_target, 10, "АВТОПУШКА")
	arena._deal_weapon_damage(dps_target, 1000, "АВТОПУШКА")
	assert(arena.training_damage == 30 and is_equal_approx(arena.current_dps, 6.0))
	arena.manual_paused = true
	arena._process(10.0)
	assert(arena.dps_clock == 0.0 and is_equal_approx(arena.current_dps, 6.0))
	arena.manual_paused = false
	arena.dps_clock = 5.01
	arena._update_training_dps()
	assert(arena.current_dps == 0.0)
	arena._equip_test_weapon("fan")
	assert(arena.training_damage == 0 and arena.dps_hits.is_empty())
	arena._equip_test_weapon("")
	arena._update_training_respawns(2.01)
	await process_frame
	# Exercise real weapon/projectile updates, not only upgrade configuration.
	for key in arena.WEAPON_NAMES:
		arena.test_weapon_level = 7
		arena._equip_test_weapon(key)
		arena.mech_position = Vector2(280, 350) if key == "shuriken" else Vector2(240, 450)
		if key == "heat":
			arena.mech_position = Vector2(240, 400)
		arena.nearest_target = null
		for frame in range(240):
			arena._process(1.0 / 60.0)
			await process_frame
		assert(arena.training_damage > 0, "Weapon must damage training targets: " + key)
		assert(arena.current_dps > 0.0 and is_equal_approx(arena.dps_bar.value, arena.current_dps))
		assert(arena.mech_health == arena.mech_max_health)
		assert(arena.enemy_rocket_pool.all(func(rocket): return not rocket.active))
	arena._equip_test_weapon("")
	arena.queue_free()
	await process_frame
	var normal = load("res://scenes/main.tscn").instantiate()
	root.add_child(normal)
	normal.set_process(false)
	assert(normal.autocannon.enabled)
	assert(normal.move_speed == 72.0)
	normal.queue_free()
	await process_frame
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	assert(menu.has_node("LevelPanel/TestArena"))
	assert(not menu.get_node("LevelPanel").visible)
	menu._show_levels()
	assert(menu.get_node("LevelPanel/TestArena").is_visible_in_tree())
	menu.queue_free()
	await process_frame
	print("PASS: arena targets, two-second respawns, all weapons/levels, pickups, menu and normal-game isolation")
	quit()
