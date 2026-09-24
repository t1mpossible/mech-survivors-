extends SceneTree

var shots: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var target := AlienScout.new()
	root.add_child(target)
	target.global_position = Vector2(100.0, 0.0)
	target.set_process(false)

	var fan := load("res://scenes/autocannon.tscn").instantiate() as Autocannon
	fan.base_damage = 22.0
	root.add_child(fan)
	fan.projectile_requested.connect(_record_shot)
	if fan.damage != 22.0:
		_fail("Inspector base damage was not applied")
		return
	fan.tick(0.016, Vector2.ZERO, target)
	if shots.size() != 1 or shots[0].damage != 22:
		_fail("Level 1 should fire one projectile using the scene's damage")
		return
	shots.clear()
	fan.apply_upgrade("fan")
	fan.time_to_shot = 0.0
	fan.tick(0.016, Vector2.ZERO, target)
	if shots.size() != 2 or shots[0].damage != 14 or shots[1].damage != 14:
		_fail("Level 2 fan should fire two weakened projectiles")
		return
	shots.clear()

	var heavy := load("res://scenes/autocannon.tscn").instantiate() as Autocannon
	root.add_child(heavy)
	heavy.projectile_requested.connect(_record_shot)
	for upgrade_index in range(6):
		if not heavy.apply_upgrade("heavy"):
			_fail("Heavy branch upgrade failed")
			return
	heavy.tick(0.016, Vector2.ZERO, target)
	for shot_index in range(6):
		heavy.tick(0.21, Vector2.ZERO, target)
	if shots.size() != 7 or heavy.burst_shots_left != 0 or not is_equal_approx(heavy.time_to_shot, 3.0):
		_fail("Desert Eagle should fire seven shots before a three-second reload")
		return
	for shot in shots:
		if shot.damage != 30 or not shot.heavy or shot.pierce_limit != 3:
			_fail("Desert Eagle projectile settings changed")
			return
	quit()


func _record_shot(_start_position: Vector2, _target: AlienScout, damage: int, _direction: Vector2, _speed: float, _prime: bool, heavy: bool, pierce_limit: int) -> void:
	shots.append({"damage": damage, "heavy": heavy, "pierce_limit": pierce_limit})


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
