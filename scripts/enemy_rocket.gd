class_name EnemyRocket
extends Node2D

const PROJECTILE_ART := preload("res://assets/projectiles_v1.png")

var direction := Vector2.LEFT
var speed := 48.0
var damage := 7.0
var player_position := Vector2.ZERO
var lifetime := 4.0
var homing_time := 0.0
var active := false
var visual_time := 0.0

signal hit_player(amount: float)


func _ready() -> void:
	add_to_group("enemy_rockets")
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	queue_redraw()


func activate(start_position: Vector2, new_direction: Vector2, new_speed: float, new_damage: float, new_homing_time: float = 0.0, new_lifetime: float = 4.0, new_scale: Vector2 = Vector2.ONE) -> void:
	global_position = start_position
	direction = new_direction
	speed = new_speed
	damage = new_damage
	homing_time = new_homing_time
	lifetime = new_lifetime
	scale = new_scale
	visual_time = 0.0
	rotation = direction.angle()
	active = true
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT


func deactivate() -> void:
	active = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED


func _process(delta: float) -> void:
	visual_time += delta
	if homing_time > 0.0:
		direction = (player_position - global_position).normalized()
		homing_time -= delta
		rotation = direction.angle()
	global_position += direction * speed * delta
	queue_redraw()
	lifetime -= delta
	if global_position.distance_to(player_position) < 9.0:
		hit_player.emit(damage)
		deactivate()
	elif lifetime <= 0.0:
		deactivate()


func _draw() -> void:
	_draw_projectile_frame(2, Vector2(23, 13))


func _draw_projectile_frame(column: int, size: Vector2) -> void:
	var frame := int(visual_time * 12.0) % 2
	var cell := Vector2(PROJECTILE_ART.get_width() / 4.0, PROJECTILE_ART.get_height() / 2.0)
	var source := Rect2(Vector2(column * cell.x, frame * cell.y), cell)
	draw_texture_rect_region(PROJECTILE_ART, Rect2(-size * 0.5, size), source)
