class_name AlienElite
extends AlienScout

const ENEMY_ROCKET := preload("res://scenes/enemy_rocket.tscn")

var shot_time_left := 2.2


func _ready() -> void:
	movement_speed = 8.0
	max_health = 300
	health = max_health
	contact_damage_per_second = 22.0
	experience_amount = 75
	xp_tier = XpOrb.Tier.ELITE_BLUE
	super._ready()
	queue_redraw()


func _process(delta: float) -> void:
	super._process(delta)
	shot_time_left -= delta
	if shot_time_left <= 0.0 and target_position != Vector2.ZERO:
		_launch_side_rocket(Vector2(-18, 0))
		_launch_side_rocket(Vector2(18, 0))
		shot_time_left = 3.2


func _launch_side_rocket(side_offset: Vector2) -> void:
	var rocket: EnemyRocket = get_parent().call("acquire_enemy_rocket") as EnemyRocket
	if rocket != null:
		var start_position := global_position + side_offset
		rocket.activate(start_position, (target_position - start_position).normalized(), 55.0, 12.0, 1.0)


func _draw() -> void:
	# Elite launcher has two visible wing pods, which are also its firing points.
	draw_circle(Vector2(2, 6), 23.0, Color("0b111b"))
	draw_circle(Vector2.ZERO, 20.0, Color("2569a8"))
	draw_rect(Rect2(-15, -10, 30, 20), Color("377fc4"))
	draw_circle(Vector2(-7, -3), 4.0, Color("9ee8ff"))
	draw_circle(Vector2(7, -3), 4.0, Color("9ee8ff"))
	draw_rect(Rect2(-27, -5, 11, 10), Color("173c70"))
	draw_rect(Rect2(16, -5, 11, 10), Color("173c70"))
	draw_circle(Vector2(-23, 0), 3.0, Color("8ddcff"))
	draw_circle(Vector2(23, 0), 3.0, Color("8ddcff"))
	draw_rect(Rect2(-22, -29, 44, 4), Color("08111c"))
	draw_rect(Rect2(-21, -28, 42.0 * float(health) / float(max_health), 2), Color("5cc8ff"))
