class_name BossMine
extends Node2D

const ENEMY_ROCKET := preload("res://scenes/enemy_rocket.tscn")

var direction := Vector2.DOWN
var speed := 30.0
var fall_time := 1.4
var homing_time := 0.0
var fragment_damage := 15.0


func _ready() -> void:
	add_to_group("enemy_hazards")
	queue_redraw()


func _process(delta: float) -> void:
	if homing_time > 0.0:
		var main := get_parent()
		if main != null:
			direction = (main.get("mech_position") - global_position).normalized()
		homing_time -= delta
	global_position += direction * speed * delta
	fall_time -= delta
	if fall_time <= 0.0:
		_split()
		queue_free()


func _split() -> void:
	for fragment_direction in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		var fragment: EnemyRocket = get_parent().call("acquire_enemy_rocket") as EnemyRocket
		if fragment != null:
			fragment.activate(global_position, fragment_direction, 65.0, fragment_damage, 0.0, 2.5)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 7.0, Color("191321"))
	draw_circle(Vector2.ZERO, 5.0, Color("b33f69"))
	draw_circle(Vector2.ZERO, 2.0, Color("ffd06a"))
