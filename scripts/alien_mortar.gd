class_name AlienMortar
extends AlienScout
const MINE := preload("res://scenes/boss_mine.tscn")
var shot := 2.0
var split_child := false
func _ready() -> void:
	movement_speed = 7.0
	max_health = 150 if split_child else 300
	health = max_health
	hit_radius = 14.0 if split_child else 22.0
	experience_amount = 30 if split_child else 75
	xp_tier = XpOrb.Tier.LARGE_RED
	super._ready()
	queue_redraw()
func _process(delta: float) -> void:
	super._process(delta)
	shot -= delta
	if shot <= 0.0:
		if get_parent().call("allow_enemy_hazard"):
			var mine := MINE.instantiate() as BossMine
			get_parent().add_child(mine)
			mine.global_position = global_position
			mine.direction = (target_position - global_position).normalized()
			mine.speed = 51.0
			mine.homing_time = 2.5
			mine.fall_time = 2.5
		shot = 3.5
func take_damage(amount: int) -> void:
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	if health == 0:
		if not split_child and not training_dummy:
			for side in [-16.0, 16.0]:
				var child := preload("res://scenes/alien_mortar.tscn").instantiate() as AlienMortar
				child.split_child = true
				get_parent().add_child(child)
				child.global_position = global_position + Vector2(side, 0)
				get_parent()._connect_scout(child)
		died.emit()
		queue_free()


func _draw() -> void:
	_draw_enemy_art(5, 34.0 if split_child else 52.0, Color("d880ff"))
