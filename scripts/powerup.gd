class_name Powerup
extends Node2D

enum Type { SPEED, FIRE_RATE }
const POWERUP_ART := preload("res://assets/powerups_v1.png")

var type := Type.SPEED
var player_position := Vector2.ZERO
var visual_time := 0.0

signal collected(powerup_type: int)


func _ready() -> void:
	add_to_group("powerups")
	queue_redraw()


func _process(delta: float) -> void:
	visual_time += delta
	if global_position.distance_to(player_position) < 15.0:
		collected.emit(type)
		queue_free()
	queue_redraw()


func _draw() -> void:
	var cell := Vector2(POWERUP_ART.get_width() * 0.5, POWERUP_ART.get_height())
	var source := Rect2(Vector2(float(type) * cell.x, 0.0), cell)
	var pulse := 24.0 + sin(visual_time * 4.0) * 1.4
	var bob := sin(visual_time * 2.5) * 1.5
	draw_texture_rect_region(POWERUP_ART,
		Rect2(Vector2(-pulse * 0.5, -pulse * 0.5 + bob), Vector2.ONE * pulse), source)
