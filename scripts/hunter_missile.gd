class_name HunterMissile
extends Node2D

const BASE_SPEED := 95.0

var target: AlienScout
var damage := 20
var speed := BASE_SPEED
var explosion_radius := 0.0
var active := false


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	queue_redraw()


func activate(start_position: Vector2, new_target: AlienScout, new_damage: int, new_speed: float = BASE_SPEED, new_explosion_radius: float = 0.0) -> void:
	global_position = start_position
	target = new_target
	damage = new_damage
	speed = new_speed
	explosion_radius = new_explosion_radius
	active = true
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT


func deactivate() -> void:
	active = false
	visible = false
	target = null
	process_mode = Node.PROCESS_MODE_DISABLED


func _process(delta: float) -> void:
	if not is_instance_valid(target):
		deactivate()
		return

	var offset := target.global_position - global_position
	if offset.length() <= speed * delta + 6.0:
		_explode()
		deactivate()
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
