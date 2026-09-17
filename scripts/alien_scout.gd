class_name AlienScout
extends Node2D

@export var movement_speed := 24.0
@export var max_health := 30
@export var contact_damage_per_second := 8.0
var experience_amount := 10
var xp_tier := XpOrb.Tier.SMALL_YELLOW
var target_position := Vector2.ZERO
var travel_direction := Vector2.DOWN
var health := max_health
var visual_time := 0.0
var damage_flash_time := 0.0
var base_visual_scale := Vector2.ONE

signal health_changed(current_health: int, maximum_health: int)
signal died


func _ready() -> void:
	add_to_group("enemies")
	base_visual_scale = scale
	queue_redraw()


func _process(delta: float) -> void:
	visual_time += delta
	damage_flash_time = maxf(damage_flash_time - delta, 0.0)
	modulate = Color(1.0, 0.55, 0.55) if damage_flash_time > 0.0 else Color.WHITE
	var offset := target_position - global_position
	if offset.length() > 18.0:
		travel_direction = offset.normalized()
		global_position += travel_direction * movement_speed * delta
		scale = base_visual_scale * (1.0 + sin(visual_time * 7.0) * 0.025)
		queue_redraw()


func take_damage(amount: int) -> void:
	health = maxi(health - amount, 0)
	damage_flash_time = 0.1
	health_changed.emit(health, max_health)
	if health == 0:
		died.emit()
		queue_free()


func _draw() -> void:
	# Compact health bar remains visible during combat.
	draw_rect(Rect2(-10, -15, 20, 3), Color("160d18"))
	draw_rect(Rect2(-9, -14, 18.0 * float(health) / float(max_health), 1), Color("f06a9d"))
