class_name AlienTurret
extends AlienScout
const ROCKET := preload("res://scenes/enemy_rocket.tscn")
var cooldown := 1.4
func _ready() -> void:
	movement_speed = 0.0
	max_health = 90
	health = 90
	experience_amount = 30
	xp_tier = XpOrb.Tier.LARGE_RED
	super._ready()
func _process(delta: float) -> void:
	cooldown -= delta
	if cooldown <= 0.0 and target_position != Vector2.ZERO:
		var bullet := ROCKET.instantiate() as EnemyRocket
		get_parent().add_child(bullet)
		bullet.global_position = global_position
		bullet.direction = (target_position - global_position).normalized()
		bullet.speed = 120.0
		bullet.damage = 8.0
		bullet.hit_player.connect(get_parent()._take_damage)
		cooldown = 1.4
	queue_redraw()
func _draw() -> void:
	draw_circle(Vector2.ZERO, 13, Color("38305e"))
	draw_rect(Rect2(-4, -18, 8, 20), Color("a58cff"))
	draw_circle(Vector2.ZERO, 4, Color("ffcf68"))
