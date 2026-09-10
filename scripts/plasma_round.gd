class_name PlasmaRound
extends Node2D

const SPEED := 150.0

var target: AlienScout
var damage := 10


func _ready() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return

	var offset := target.global_position - global_position
	if offset.length() <= SPEED * delta + 5.0:
		target.take_damage(damage)
		queue_free()
		return

	global_position += offset.normalized() * SPEED * delta


func _draw() -> void:
	draw_circle(Vector2.ZERO, 3.0, Color("ffd166"))
	draw_circle(Vector2.ZERO, 1.3, Color("fff4c4"))
