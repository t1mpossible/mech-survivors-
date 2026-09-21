class_name AlienScout
extends Node2D

const ENEMY_ART := preload("res://assets/enemies_desert_v1.png")
const ENEMY_ART_MOTION := preload("res://assets/enemies_desert_motion_v1.png")
# Individually fitted atlas bounds: the generated artwork is not an exact tile grid.
const ART_REGIONS: Array[Rect2] = [
	Rect2(0.020, 0.105, 0.208, 0.322),
	Rect2(0.274, 0.043, 0.190, 0.383),
	Rect2(0.498, 0.025, 0.254, 0.401),
	Rect2(0.780, 0.025, 0.204, 0.401),
	Rect2(0.010, 0.539, 0.245, 0.400),
	Rect2(0.232, 0.444, 0.263, 0.510),
	Rect2(0.498, 0.445, 0.275, 0.515),
]

@export var movement_speed := 24.0
@export var max_health := 30
@export var contact_damage_per_second := 8.0
var experience_amount := 10
var xp_tier := XpOrb.Tier.SMALL_YELLOW
var target_position := Vector2.ZERO
var travel_direction := Vector2.DOWN
var health := max_health
var hit_radius := 12.0
var visual_time := 0.0
var damage_flash_time := 0.0
var base_visual_scale := Vector2.ONE
var movement_animation_active := false

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
	movement_animation_active = false
	if offset.length() > 18.0:
		travel_direction = offset.normalized()
		global_position += travel_direction * movement_speed * delta
		movement_animation_active = movement_speed > 0.0
		scale = base_visual_scale * (1.0 + sin(visual_time * 7.0) * 0.01)
		queue_redraw()


func take_damage(amount: int) -> void:
	health = maxi(health - amount, 0)
	damage_flash_time = 0.1
	health_changed.emit(health, max_health)
	if health == 0:
		died.emit()
		queue_free()


func _draw() -> void:
	_draw_enemy_art(0, 30.0, Color("f06a9d"))


func _draw_enemy_art(kind: int, width: float, bar_color: Color) -> void:
	var bounds := ART_REGIONS[kind]
	var art := ENEMY_ART
	if movement_animation_active and int(visual_time * 5.0) % 2 == 1:
		art = ENEMY_ART_MOTION
	var source := Rect2(bounds.position * art.get_size(), bounds.size * art.get_size())
	if kind < 6:
		width *= 1.2
	var size := Vector2(width, width * source.size.y / source.size.x)
	draw_texture_rect_region(art, Rect2(-size * 0.5, size), source)
	var bar_width := width * 0.75
	var bar_y := -size.y * 0.5 - 5.0
	draw_rect(Rect2(-bar_width * 0.5, bar_y, bar_width, 3.0), Color("160d18"))
	draw_rect(Rect2(-bar_width * 0.5 + 1.0, bar_y + 1.0,
		(bar_width - 2.0) * float(health) / float(max_health), 1.0), bar_color)
