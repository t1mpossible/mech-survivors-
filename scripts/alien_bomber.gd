class_name AlienBomber
extends AlienScout

var pulse := 0.0


func _ready() -> void:
	movement_speed = 15.0
	max_health = 90
	health = max_health
	contact_damage_per_second = 0.0
	experience_amount = 30
	xp_tier = XpOrb.Tier.LARGE_RED
	super._ready()


func _process(delta: float) -> void:
	super._process(delta)
	pulse += delta * 5.0
	if global_position.distance_to(target_position) < 42.0:
		get_parent()._take_damage(30.0)
		died.emit()
		queue_free()
	queue_redraw()


func _draw() -> void:
	var halo_radius := 17.0 + sin(pulse) * 3.0
	draw_circle(Vector2.ZERO, halo_radius, Color(1.0, 0.15, 0.18, 0.18))
	draw_circle(Vector2.ZERO, 11.0, Color("8c263b"))
	draw_circle(Vector2.ZERO, 7.0, Color("d6494f"))
	draw_circle(Vector2.ZERO, 3.0, Color("ffd36d"))
	draw_rect(Rect2(-12, -17, 24, 3), Color("160d18"))
	draw_rect(Rect2(-11, -16, 22.0 * float(health) / float(max_health), 1), Color("f05b61"))
