class_name EnemyRocket
extends Node2D

var direction := Vector2.LEFT
var speed := 48.0
var damage := 7.0
var player_position := Vector2.ZERO
var lifetime := 4.0
var homing_time := 0.0

signal hit_player(amount: float)


func _ready() -> void:
	add_to_group("enemy_rockets")
	rotation = direction.angle()
	queue_redraw()


func _process(delta: float) -> void:
	if homing_time > 0.0:
		direction = (player_position - global_position).normalized()
		homing_time -= delta
		rotation = direction.angle()
	global_position += direction * speed * delta
	lifetime -= delta
	if global_position.distance_to(player_position) < 9.0:
		hit_player.emit(damage)
		queue_free()
	elif lifetime <= 0.0:
		queue_free()


func _draw() -> void:
	draw_circle(Vector2(-4, 0), 2.5, Color("ff7b45"))
	draw_rect(Rect2(-1, -2, 7, 4), Color("d9e6ec"))
	draw_circle(Vector2(6, 0), 1.5, Color("ff4b4b"))
