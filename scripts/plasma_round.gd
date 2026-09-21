class_name PlasmaRound
extends Node2D

const SPEED := 150.0
const ORPHAN_FLIGHT_TIME := 4.5
const PROJECTILE_ART := preload("res://assets/projectiles_v1.png")

var target: AlienScout
var damage := 10
var active := false
var visual_time := 0.0
var travel_direction := Vector2.RIGHT
var orphan_flight_time := 0.0


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	queue_redraw()


func activate(start_position: Vector2, new_target: AlienScout, new_damage: int) -> void:
	global_position = start_position
	target = new_target
	damage = new_damage
	visual_time = 0.0
	orphan_flight_time = 0.0
	if is_instance_valid(target):
		travel_direction = (target.global_position - global_position).normalized()
		rotation = travel_direction.angle()
	active = true
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT


func deactivate() -> void:
	active = false
	visible = false
	target = null
	process_mode = Node.PROCESS_MODE_DISABLED


func _process(delta: float) -> void:
	visual_time += delta
	if orphan_flight_time > 0.0:
		global_position += travel_direction * SPEED * delta
		orphan_flight_time -= delta
		if orphan_flight_time <= 0.0:
			deactivate()
		else:
			queue_redraw()
		return
	if not is_instance_valid(target):
		_begin_orphan_flight()
		return

	var offset := target.global_position - global_position
	travel_direction = offset.normalized()
	rotation = travel_direction.angle()
	if offset.length() <= SPEED * delta + 5.0:
		target.take_damage(damage)
		deactivate()
		return

	global_position += travel_direction * SPEED * delta
	queue_redraw()


func _begin_orphan_flight() -> void:
	target = null
	orphan_flight_time = ORPHAN_FLIGHT_TIME
	queue_redraw()


func _draw() -> void:
	_draw_projectile_frame(0, Vector2(20, 11))


func _draw_projectile_frame(column: int, size: Vector2) -> void:
	var frame := int(visual_time * 12.0) % 2
	var cell := Vector2(PROJECTILE_ART.get_width() / 4.0, PROJECTILE_ART.get_height() / 2.0)
	var source := Rect2(Vector2(column * cell.x, frame * cell.y), cell)
	draw_texture_rect_region(PROJECTILE_ART, Rect2(-size * 0.5, size), source)
