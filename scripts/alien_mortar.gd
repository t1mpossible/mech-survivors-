class_name AlienMortar
extends AlienScout
const MINE := preload("res://scenes/boss_mine.tscn")
var shot := 2.0
var split_child := false
func _ready() -> void:
	movement_speed = 7.0
	max_health = 150 if split_child else 300
	health = max_health
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
		if not split_child:
			for side in [-16.0, 16.0]:
				var child := preload("res://scenes/alien_mortar.tscn").instantiate() as AlienMortar
				child.split_child = true
				get_parent().add_child(child)
				child.global_position = global_position + Vector2(side, 0)
				get_parent()._connect_scout(child)
		died.emit()
		queue_free()


func _draw() -> void:
	var body_color := Color("84518d") if split_child else Color("633b8f")
	var armor_color := Color("b977d6") if split_child else Color("9e63cc")
	var size := 13.0 if split_child else 20.0
	draw_circle(Vector2(2, 5), size + 2.0, Color("100e1b"))
	draw_circle(Vector2.ZERO, size, body_color)
	draw_rect(Rect2(-size, 5, size * 2.0, 8), Color("342342"))
	draw_rect(Rect2(-size + 3.0, 7, size * 2.0 - 6.0, 3), Color("73527e"))
	draw_rect(Rect2(-5, -size - 8, 10, size + 10), armor_color)
	draw_circle(Vector2.ZERO, 5.0, Color("f4d36b"))
	draw_circle(Vector2.ZERO, 2.0, Color("fff4bd"))
	draw_rect(Rect2(-size, -size - 14, size * 2.0, 4), Color("160d18"))
	draw_rect(Rect2(-size + 1.0, -size - 13, (size * 2.0 - 2.0) * float(health) / float(max_health), 2), Color("d880ff"))
