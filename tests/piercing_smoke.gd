extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := load("res://scenes/main.tscn").instantiate() as Node2D
	root.add_child(game)
	game.set_process(false)
	var enemies: Array[AlienScout] = []
	for enemy_x in [120.0, 160.0, 200.0]:
		var enemy := AlienScout.new()
		game.add_child(enemy)
		enemy.global_position = Vector2(enemy_x, 100.0)
		enemy.set_process(false)
		enemies.append(enemy)
	var round := game.call("acquire_plasma_round") as PlasmaRound
	round.activate(Vector2(100.0, 100.0), enemies[0], 5, Vector2.RIGHT, 1.0, false, true, 2)
	round.set_process(false)
	round._process(0.6)
	if not round.active or enemies[0].health != 25 or enemies[1].health != 25 or enemies[2].health != 30:
		push_error("Piercing round must continue after two hits without damaging a third enemy")
		quit(1)
		return
	var x_after_hits := round.global_position.x
	round._process(0.1)
	if not round.active or round.global_position.x <= x_after_hits or enemies[2].health != 30:
		push_error("Piercing round stopped or dealt damage after its hit limit")
		quit(1)
		return
	quit()
