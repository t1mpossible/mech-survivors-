extends SceneTree


class GameStub extends Node:
	var effect_scales: Array[float] = []

	func spawn_combat_effect(_world_position: Vector2, _effect_type: int, effect_scale: float = 1.0) -> void:
		effect_scales.append(effect_scale)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameStub.new()
	root.add_child(game)
	var projectiles := Node2D.new()
	game.add_child(projectiles)
	var missile := load("res://scenes/hunter_missile.tscn").instantiate() as HunterMissile
	projectiles.add_child(missile)
	await process_frame

	missile.missile_style = "swarm"
	missile.explosion_radius = 0.0
	missile._spawn_explosion()
	assert(is_equal_approx(game.effect_scales.back(), 0.62))

	missile.missile_style = "siege"
	missile.explosion_radius = 55.0
	missile._spawn_explosion()
	assert(is_equal_approx(game.effect_scales.back(), 1.70))
	assert(game.effect_scales[1] > game.effect_scales[0])

	print("PASS: swarm impacts stay compact and siege impacts scale up visually")
	quit()
