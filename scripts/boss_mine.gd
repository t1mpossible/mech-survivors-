class_name BossMine
extends Node2D

const ENEMY_ROCKET := preload("res://scenes/enemy_rocket.tscn")
const PROJECTILE_ART := preload("res://assets/projectiles_v1.png")

var direction := Vector2.DOWN
var speed := 30.0
var fall_time := 1.4
var homing_time := 0.0
var fragment_damage := 15.0
var visual_time := 0.0


func _ready() -> void:
	add_to_group("enemy_hazards")
	queue_redraw()


func _process(delta: float) -> void:
	visual_time += delta
	if homing_time > 0.0:
		var main := get_parent()
		if main != null:
			direction = (main.get("mech_position") - global_position).normalized()
		homing_time -= delta
	global_position += direction * speed * delta
	rotation += delta * 1.5
	fall_time -= delta
	if fall_time <= 0.0:
		_split()
		queue_free()
	queue_redraw()


func _split() -> void:
	for fragment_direction in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		var fragment: EnemyRocket = get_parent().call("acquire_enemy_rocket") as EnemyRocket
		if fragment != null:
			fragment.activate(global_position, fragment_direction, 65.0, fragment_damage, 0.0, 2.5)


func _draw() -> void:
	var frame := int(visual_time * 8.0) % 2
	var cell := Vector2(PROJECTILE_ART.get_width() / 4.0, PROJECTILE_ART.get_height() / 2.0)
	var source := Rect2(Vector2(3.0 * cell.x, frame * cell.y), cell)
	draw_texture_rect_region(PROJECTILE_ART, Rect2(-Vector2(21, 21) * 0.5, Vector2(21, 21)), source)
