class_name AlienElite
extends AlienScout

const ENEMY_ROCKET := preload("res://scenes/enemy_rocket.tscn")

var shot_time_left := 2.2


func _ready() -> void:
	movement_speed = 8.0
	max_health = 300
	health = max_health
	contact_damage_per_second = 22.0
	hit_radius = 24.0
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
	_draw_enemy_art(2, 56.0, Color("5cc8ff"))
