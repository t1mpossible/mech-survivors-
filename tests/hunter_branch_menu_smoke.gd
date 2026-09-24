extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Variant = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.autocannon.apply_upgrade("fan")
	game.hunter_launcher.unlock()
	game._open_upgrade_choice()
	if game.available_upgrades[0].kind != "missile_branch_swarm" or game.available_upgrades[1].kind != "missile_branch_siege":
		_fail("Both rocket branches must be visible in the two weapon choices")
		return
	if not paused or not game.get_node("Hud/UpgradePanel").visible:
		_fail("Branch choice must pause combat")
		return
	game._choose_upgrade(1)
	if game.hunter_launcher.branch != "siege" or game.hunter_launcher.level != 2 or paused:
		_fail("Choosing siege should lock the branch and resume combat")
		return
	quit()


func _fail(message: String) -> void:
	paused = false
	push_error(message)
	quit(1)
