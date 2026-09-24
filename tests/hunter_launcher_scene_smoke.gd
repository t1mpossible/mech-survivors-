extends SceneTree

var shots: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var target := AlienScout.new()
	root.add_child(target)
	target.global_position = Vector2(100.0, 0.0)
	target.set_process(false)

	var swarm := load("res://scenes/hunter_launcher.tscn").instantiate() as HunterLauncher
	root.add_child(swarm)
	swarm.missile_requested.connect(_record_shot)
	swarm.unlock()
	swarm.tick(0.2, Vector2.ZERO, target)
	if shots.size() != 1 or shots[0].damage != 22 or shots[0].speed != 95.0:
		_fail("Shared level 1 must fire one rocket for 22 damage")
		return
	if not swarm.choose_branch("swarm") or swarm.choose_branch("siege"):
		_fail("Rocket branch choice must lock at level 2")
		return
	for upgrade_index in range(5):
		if not swarm.upgrade():
			_fail("Swarm upgrade failed")
			return
	shots.clear()
	swarm.time_to_shot = 0.0
	swarm.tick(0.016, Vector2.ZERO, target)
	if swarm.level != 7 or shots.size() != 6:
		_fail("Yellow Storm must fire six rockets")
		return
	for shot in shots:
		if shot.damage != 15 or shot.speed != 122.0 or shot.style != "swarm":
			_fail("Yellow Storm level 7 statistics changed")
			return
	if shots[0].arc_offset == shots[5].arc_offset:
		_fail("Swarm rockets need different arcs")
		return

	var siege := load("res://scenes/hunter_launcher.tscn").instantiate() as HunterLauncher
	root.add_child(siege)
	siege.missile_requested.connect(_record_shot)
	siege.unlock()
	if not siege.choose_branch("siege"):
		_fail("Siege branch choice failed")
		return
	for upgrade_index in range(5):
		siege.upgrade()
	shots.clear()
	siege.time_to_shot = 0.0
	siege.tick(0.016, Vector2.ZERO, target)
	if siege.level != 7 or shots.size() != 1 or shots[0].damage != 55 or shots[0].radius != 55.0 or shots[0].blasts != 3 or shots[0].pause != 0.25:
		_fail("Siege level 7 must request three delayed blasts")
		return
	quit()


func _record_shot(_start_position: Vector2, _target: AlienScout, damage: int, speed: float, radius: float, blasts: int, pause: float, arc_offset: float, style: String) -> void:
	shots.append({"damage": damage, "speed": speed, "radius": radius, "blasts": blasts, "pause": pause, "arc_offset": arc_offset, "style": style})


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
