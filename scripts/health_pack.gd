class_name HealthPack
extends Node2D

const HEAL_FRACTION := 0.25

var player_position := Vector2.ZERO

signal collected(heal_fraction: float)


func _ready() -> void:
	add_to_group("health_packs")
	queue_redraw()


func _process(_delta: float) -> void:
	if global_position.distance_to(player_position) < 12.0:
		collected.emit(HEAL_FRACTION)
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 7.0, Color("0a1818"))
	draw_rect(Rect2(-5, -2, 10, 4), Color("59d986"))
	draw_rect(Rect2(-2, -5, 4, 10), Color("59d986"))
	draw_rect(Rect2(-1, -4, 2, 8), Color("d9ffdf"))
	draw_rect(Rect2(-4, -1, 8, 2), Color("d9ffdf"))
