extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var dead_target := AlienScout.new()
	root.add_child(dead_target)
	dead_target.global_position = Vector2(80.0, 0.0)
	dead_target.set_process(false)
	var new_target := AlienScout.new()
	root.add_child(new_target)
	new_target.global_position = Vector2(0.0, 100.0)
	new_target.set_process(false)
	var missile := load("res://scenes/hunter_missile.tscn").instantiate() as HunterMissile
	root.add_child(missile)
	missile.activate(Vector2.ZERO, dead_target, 22)
	missile.set_process(false)
	dead_target.health = 0
	missile._process(0.1)
	if missile.target != new_target or missile.orphan_flight_time > 0.0 or missile.global_position.y <= 0.0:
		_fail("Missile did not retarget to a living enemy")
		return
	if missile.rotation <= 0.0 or missile.rotation > deg_to_rad(missile.turn_degrees_per_second) * 0.1 + 0.001:
		_fail("Missile must turn gradually instead of snapping to the new target")
		return
	if not is_equal_approx(missile.global_position.length(), missile.speed * 0.1):
		_fail("Missile must keep its full flight speed while turning")
		return
	var freed_target := AlienScout.new()
	root.add_child(freed_target)
	freed_target.global_position = Vector2(90.0, 0.0)
	freed_target.set_process(false)
	var second_missile := load("res://scenes/hunter_missile.tscn").instantiate() as HunterMissile
	root.add_child(second_missile)
	second_missile.activate(Vector2.ZERO, freed_target, 22)
	second_missile.set_process(false)
	freed_target.free()
	second_missile._process(0.1)
	if second_missile.target != new_target or second_missile.orphan_flight_time > 0.0:
		_fail("Missile did not retarget after its target was freed")
		return
	for frame in range(200):
		if not second_missile.active:
			break
		second_missile._process(0.05)
	if second_missile.active or new_target.health != 8:
		_fail("Smoothly turning missile did not reach and damage its new target")
		return
	new_target.health = 0
	missile._process(0.1)
	if missile.target != null or not is_equal_approx(missile.orphan_flight_time, HunterMissile.ORPHAN_FLIGHT_TIME):
		_fail("Missile should continue straight when no living target remains")
		return
	quit()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
