extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _assert_unique(game: Node) -> void:
	assert(game.available_upgrades.size() == 4)
	var kinds: Array[String] = []
	for choice in game.available_upgrades:
		assert(not kinds.has(String(choice.kind)), "Repeated upgrade in the same choice: %s" % choice.kind)
		kinds.append(String(choice.kind))


func _run() -> void:
	var game: Variant = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	for attempt in range(40):
		game._open_upgrade_choice()
		_assert_unique(game)
		game.upgrade_open = false
		game.get_node("Hud/HudScale/UpgradePanel").hide()
		paused = false
	game.autocannon.branch = "fan"
	game.autocannon.level = 2
	game.hunter_launcher.unlock()
	game.hunter_launcher.branch = "swarm"
	game.hunter_launcher.level = 2
	game.laser.unlock()
	game.laser.branch = "burn"
	game.laser.level = 2
	game.orbit_weapon.unlock()
	game.orbit_weapon.branch = "shuriken"
	game.orbit_weapon.level = 2
	game._sync_orbit_weapon()
	for attempt in range(40):
		game._open_upgrade_choice()
		_assert_unique(game)
		game.upgrade_open = false
		game.get_node("Hud/HudScale/UpgradePanel").hide()
		paused = false
	game.queue_free()
	await process_frame
	print("PASS: upgrade offers never contain duplicate kinds")
	quit()
