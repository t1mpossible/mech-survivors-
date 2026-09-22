class_name HealthPack
extends Node2D

const HEAL_FRACTION := 0.25
const HEALTH_PACK_ART := preload("res://assets/health_pack_v1.png")

var player_position := Vector2.ZERO
var visual_time := 0.0

signal collected(heal_fraction: float)


func _ready() -> void:
	add_to_group("health_packs")
	queue_redraw()


func _process(delta: float) -> void:
	visual_time += delta
	if global_position.distance_to(player_position) < 15.0:
		collected.emit(HEAL_FRACTION)
		queue_free()
	queue_redraw()


func _draw() -> void:
	var size := 25.0 + sin(visual_time * 4.0) * 1.2
	var bob := sin(visual_time * 2.5) * 1.4
	draw_texture_rect(HEALTH_PACK_ART,
		Rect2(Vector2(-size * 0.5, -size * 0.5 + bob), Vector2.ONE * size), false)
