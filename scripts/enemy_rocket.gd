class_name EnemyRocket
extends Node2D

var direction := Vector2.LEFT
var speed := 48.0
var damage := 7.0
var player_position := Vector2.ZERO
var lifetime := 4.0
var homing_time := 0.0
var active := false

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
	rotation = direction.angle()
	active = true
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT


func deactivate() -> void:
	active = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED


func _process(delta: float) -> void:
	if homing_time > 0.0:
		direction = (player_position - global_position).normalized()
		homing_time -= delta
		rotation = direction.angle()
	global_position += direction * speed * delta
	lifetime -= delta
	if global_position.distance_to(player_position) < 9.0:
		hit_player.emit(damage)
		deactivate()
	elif lifetime <= 0.0:
		deactivate()


func _draw() -> void:
	draw_circle(Vector2(-4, 0), 2.5, Color("ff7b45"))
	draw_rect(Rect2(-1, -2, 7, 4), Color("d9e6ec"))
	draw_circle(Vector2(6, 0), 1.5, Color("ff4b4b"))
