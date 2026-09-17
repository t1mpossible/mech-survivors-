class_name PlasmaRound
extends Node2D

const SPEED := 150.0

var target: AlienScout
var damage := 10
var active := false


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	queue_redraw()


func activate(start_position: Vector2, new_target: AlienScout, new_damage: int) -> void:
	global_position = start_position
	target = new_target
	damage = new_damage
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
	if offset.length() <= SPEED * delta + 5.0:
		target.take_damage(damage)
		deactivate()
		return

	global_position += offset.normalized() * SPEED * delta


func _draw() -> void:
	draw_line(Vector2(-9, 0), Vector2(-2, 0), Color(1.0, 0.55, 0.2, 0.35), 2.0)
	draw_circle(Vector2.ZERO, 3.0, Color("ffd166"))
	draw_circle(Vector2.ZERO, 1.3, Color("fff4c4"))
