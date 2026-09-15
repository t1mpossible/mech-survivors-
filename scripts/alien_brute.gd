class_name AlienBrute
extends AlienScout

const ENEMY_ROCKET := preload("res://scenes/enemy_rocket.tscn")

var shot_time_left := 1.8


func _ready() -> void:
	movement_speed = 12.0
	max_health = 90
	health = max_health
	contact_damage_per_second = 14.0
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
	var rocket := ENEMY_ROCKET.instantiate() as EnemyRocket
	get_parent().add_child(rocket)
	rocket.global_position = global_position
	rocket.direction = (target_position - global_position).normalized()
	rocket.speed = 42.0
	rocket.damage = 7.0
	rocket.hit_player.connect(get_parent()._take_damage)


func _draw() -> void:
	# A slow armored alien: strong against the basic cannon, rewarding for rockets.
	draw_circle(Vector2(2, 5), 17.0, Color("0d1018"))
	draw_circle(Vector2.ZERO, 14.0, Color("8f3848"))
	draw_rect(Rect2(-11, -7, 22, 13), Color("b74c55"))
	draw_circle(Vector2(-5, -2), 3.5, Color("ffcc70"))
	draw_circle(Vector2(5, -2), 3.5, Color("ffcc70"))
	draw_circle(Vector2(-5, -2), 1.3, Color("301720"))
	draw_circle(Vector2(5, -2), 1.3, Color("301720"))
	draw_rect(Rect2(-15, 7, 6, 9), Color("582738"))
	draw_rect(Rect2(9, 7, 6, 9), Color("582738"))
	draw_rect(Rect2(-15, -22, 30, 4), Color("160d18"))
	draw_rect(Rect2(-14, -21, 28.0 * float(health) / float(max_health), 2), Color("f05b61"))
