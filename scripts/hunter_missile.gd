class_name HunterMissile
extends Node2D

const BASE_SPEED := 95.0

var target: AlienScout
var damage := 20
var speed := BASE_SPEED
var explosion_radius := 0.0


func _ready() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return

	var offset := target.global_position - global_position
	if offset.length() <= speed * delta + 6.0:
		_explode()
		queue_free()
		return

	global_position += offset.normalized() * speed * delta
	rotation = offset.angle()


func _explode() -> void:
	if explosion_radius <= 0.0:
		target.take_damage(damage)
		return
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as AlienScout
		if enemy != null and enemy.global_position.distance_to(global_position) <= explosion_radius:
			enemy.take_damage(damage)


func _draw() -> void:
	draw_circle(Vector2(-4, 0), 3.0, Color("ff873d"))
	draw_rect(Rect2(-2, -2, 7, 4), Color("d8e9f3"))
	draw_circle(Vector2(5, 0), 2.0, Color("ff5d4a"))
	draw_line(Vector2(1, -2), Vector2(1, -5), Color("d8e9f3"), 1.0)
	draw_line(Vector2(1, 2), Vector2(1, 5), Color("d8e9f3"), 1.0)
