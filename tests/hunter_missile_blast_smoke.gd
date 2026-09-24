extends SceneTree

class FakeGame extends Node2D:
	var hits := 0

	func _deal_weapon_damage(_enemy: AlienScout, _damage: int, _weapon: String) -> void:
		hits += 1

	func spawn_combat_effect(_position: Vector2, _kind: int, _size: float) -> void:
		pass


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := FakeGame.new()
	root.add_child(game)
	var projectiles := Node2D.new()
	game.add_child(projectiles)
	var target := AlienScout.new()
	game.add_child(target)
	target.global_position = Vector2(3.0, 0.0)
	target.add_to_group("enemies")
	target.set_process(false)
	var missile := load("res://scenes/hunter_missile.tscn").instantiate() as HunterMissile
	projectiles.add_child(missile)
	missile.activate(Vector2.ZERO, target, 55, 95.0, 55.0, 3, 0.25, 0.0, "siege")
	missile.set_process(false)
	missile._process(0.016)
	if game.hits != 1 or not missile.active or not missile.exploding:
		_fail("First blast must damage and keep the projectile reserved")
		return
	missile._process(0.25)
	if game.hits != 2 or not missile.active:
		_fail("Second blast must follow after 0.25 seconds")
		return
	missile._process(0.25)
	if game.hits != 3 or missile.active:
		_fail("Third blast must damage and release the projectile")
		return
	quit()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
