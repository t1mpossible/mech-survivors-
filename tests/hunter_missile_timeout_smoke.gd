extends SceneTree

class FakeGame extends Node2D:
	var hits := 0
	var explosions := 0

	func _deal_weapon_damage(_enemy: AlienScout, _damage: int, _weapon: String) -> void:
		hits += 1

	func spawn_combat_effect(_position: Vector2, _kind: int, _size: float) -> void:
		explosions += 1


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := FakeGame.new()
	root.add_child(game)
	var projectiles := Node2D.new()
	game.add_child(projectiles)
	var target := AlienScout.new()
	game.add_child(target)
	target.global_position = Vector2(2000.0, 0.0)
	target.add_to_group("enemies")
	target.set_process(false)
	var missile := load("res://scenes/hunter_missile.tscn").instantiate() as HunterMissile
	projectiles.add_child(missile)
	missile.set_process(false)
	if not is_equal_approx(missile.maximum_guided_flight_time, 8.0):
		_fail("Guided missile fuse must be 8 seconds")
		return
	missile.activate(Vector2.ZERO, target, 22, 95.0)
	missile.set_process(false)
	missile._process(7.9)
	if not missile.active or game.explosions != 0:
		_fail("Missile must keep flying before 8 seconds")
		return
	missile._process(0.11)
	if missile.active or game.explosions != 1 or game.hits != 0:
		_fail("Swarm missile must explode at 8 seconds without hitting a distant target")
		return
	missile.activate(Vector2.ZERO, target, 55, 95.0, 55.0, 3, 0.25, 0.0, "siege")
	missile.set_process(false)
	missile._process(8.01)
	if not missile.active or not missile.exploding or game.explosions != 2 or game.hits != 0:
		_fail("Siege missile must start its three local blasts at 8 seconds")
		return
	missile._process(0.25)
	missile._process(0.25)
	if missile.active or game.explosions != 4 or game.hits != 0:
		_fail("Siege missile must finish all blasts and release itself")
		return
	quit()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
