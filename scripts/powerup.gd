class_name Powerup
extends Node2D

enum Type { SPEED, FIRE_RATE }

var type := Type.SPEED
var player_position := Vector2.ZERO

signal collected(powerup_type: int)


func _ready() -> void:
	add_to_group("powerups")
	queue_redraw()


func _process(_delta: float) -> void:
	if global_position.distance_to(player_position) < 12.0:
		collected.emit(type)
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 8.0, Color("101b29"))
	if type == Type.SPEED:
		draw_circle(Vector2.ZERO, 6.0, Color("4acbff"))
		draw_line(Vector2(-3, -3), Vector2(1, 0), Color.WHITE, 2.0)
		draw_line(Vector2(1, 0), Vector2(-3, 3), Color.WHITE, 2.0)
		draw_line(Vector2(0, -3), Vector2(4, 0), Color.WHITE, 2.0)
		draw_line(Vector2(4, 0), Vector2(0, 3), Color.WHITE, 2.0)
	else:
		draw_circle(Vector2.ZERO, 6.0, Color("ff9a45"))
		for height in [-3.0, 0.0, 3.0]:
			draw_rect(Rect2(-4, height - 1.0, 5, 2), Color.WHITE)
			draw_line(Vector2(2, height), Vector2(5, height), Color.WHITE, 1.0)
