extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var effect := load("res://scenes/combat_effect.tscn").instantiate() as CombatEffect
	root.add_child(effect)
	await process_frame
	effect.activate(Vector2(20.0, 20.0), CombatEffect.Type.ROCKET_EXPLOSION, 1.0)
	assert(effect.burst_sprite.visible)
	assert(effect.burst_sprite.texture != null)
	assert(effect.burst_sprite.hframes == 3)
	assert(effect.burst_sprite.frame == 0)

	effect.activate(Vector2(40.0, 20.0), CombatEffect.Type.ENEMY_DEATH, 1.0)
	assert(effect.burst_sprite.visible)
	assert(effect.burst_sprite.texture != null)
	assert(effect.burst_sprite.hframes == 4)
	assert(is_equal_approx(effect.duration, 0.54))
	var universal_death_texture := effect.burst_sprite.texture
	effect._update_animated_burst(0.78)
	assert(effect.burst_sprite.frame == 3)

	effect.activate(Vector2(60.0, 20.0), CombatEffect.Type.ENEMY_DISSOLVE, 1.0)
	assert(not effect.burst_sprite.visible)
	assert(is_equal_approx(effect.duration, 0.34))
	print("PASS: heavy deaths use the four-frame explosion; regular deaths use blue energy")
	quit()
