class_name BossMine
extends Node2D

const ENEMY_ROCKET := preload("res://scenes/enemy_rocket.tscn")

var direction := Vector2.DOWN
var speed := 30.0
var fall_time := 1.4
var fragment_damage := 15.0


func _ready() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	global_position += direction * speed * delta
	fall_time -= delta
	if fall_time <= 0.0:
		_split()
		queue_free()


func _split() -> void:
	for fragment_direction in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		var fragment := ENEMY_ROCKET.instantiate() as EnemyRocket
		get_parent().add_child(fragment)
		fragment.global_position = global_position
		fragment.direction = fragment_direction
		fragment.speed = 65.0
		fragment.damage = fragment_damage
		fragment.lifetime = 2.5
		fragment.hit_player.connect(get_parent()._take_damage)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 7.0, Color("191321"))
	draw_circle(Vector2.ZERO, 5.0, Color("b33f69"))
	draw_circle(Vector2.ZERO, 2.0, Color("ffd06a"))
