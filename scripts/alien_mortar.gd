class_name AlienMortar
extends AlienScout
const MINE := preload("res://scenes/boss_mine.tscn")
var shot := 2.0
var split_child := false
func _ready() -> void:
	movement_speed = 9.0
	max_health = 150 if split_child else 300
	health = max_health
	experience_amount = 30 if split_child else 75
	xp_tier = XpOrb.Tier.LARGE_RED
	super._ready()
func _process(delta: float) -> void:
	super._process(delta)
	shot -= delta
	if shot <= 0.0:
		var mine := MINE.instantiate() as BossMine
		get_parent().add_child(mine)
		mine.global_position = global_position
		mine.direction = (target_position - global_position).normalized()
		shot = 3.5
func take_damage(amount: int) -> void:
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	if health == 0:
		if not split_child:
			for side in [-16.0, 16.0]:
				var child := preload("res://scenes/alien_mortar.tscn").instantiate() as AlienMortar
				child.split_child = true
				get_parent().add_child(child)
				child.global_position = global_position + Vector2(side, 0)
		died.emit()
		queue_free()
