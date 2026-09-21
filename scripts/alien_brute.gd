class_name AlienBrute
extends AlienScout

const ENEMY_ROCKET := preload("res://scenes/enemy_rocket.tscn")

var shot_time_left := 1.8


func _ready() -> void:
	movement_speed = 12.0
	max_health = 90
	health = max_health
	contact_damage_per_second = 14.0
	hit_radius = 16.0
	experience_amount = 30
	xp_tier = XpOrb.Tier.LARGE_RED
	scale = Vector2(0.72, 0.72)
	super._ready()
	queue_redraw()


func _process(delta: float) -> void:
	super._process(delta)
	shot_time_left -= delta
	if shot_time_left <= 0.0 and target_position != Vector2.ZERO:
		_launch_rocket()
		shot_time_left = 2.8


func _launch_rocket() -> void:
	var rocket: EnemyRocket = get_parent().call("acquire_enemy_rocket") as EnemyRocket
	if rocket != null:
		rocket.activate(global_position, (target_position - global_position).normalized(), 42.0, 7.0, 1.0)


func _draw() -> void:
	_draw_enemy_art(1, 42.0, Color("f05b61"))
