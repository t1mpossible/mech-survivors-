class_name AlienTurret
extends AlienScout
const ROCKET := preload("res://scenes/enemy_rocket.tscn")
var cooldown := 1.4
func _ready() -> void:
	movement_speed = 0.0
	max_health = 90
	health = 90
	hit_radius = 14.0
	experience_amount = 30
	xp_tier = XpOrb.Tier.LARGE_RED
	super._ready()
func _process(delta: float) -> void:
	cooldown -= delta
	if cooldown <= 0.0 and target_position != Vector2.ZERO:
		var bullet: EnemyRocket = get_parent().call("acquire_enemy_rocket") as EnemyRocket
		if bullet != null:
			bullet.activate(global_position, (target_position - global_position).normalized(), 90.0, 18.0, 0.5)
		cooldown = 1.4
	queue_redraw()
func _draw() -> void:
	_draw_enemy_art(4, 34.0, Color("b38cff"))
