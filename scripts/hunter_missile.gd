class_name HunterMissile
extends Node2D

const BASE_SPEED := 95.0
const ORPHAN_FLIGHT_TIME := 4.5
const PROJECTILE_ART := preload("res://assets/projectiles_v1.png")

var target: AlienScout
var damage := 20
var speed := BASE_SPEED
var explosion_radius := 0.0
var active := false
var visual_time := 0.0
var travel_direction := Vector2.RIGHT
var orphan_flight_time := 0.0


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
		global_position += travel_direction * speed * delta
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
	if offset.length() <= speed * delta + 6.0:
		_explode()
		deactivate()
		return

	global_position += travel_direction * speed * delta
	rotation = travel_direction.angle()
	queue_redraw()


func _begin_orphan_flight() -> void:
	target = null
	orphan_flight_time = ORPHAN_FLIGHT_TIME
	queue_redraw()


func _explode() -> void:
	_spawn_explosion()
	if explosion_radius <= 0.0:
		target.take_damage(damage)
		return
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as AlienScout
		if enemy != null and enemy.global_position.distance_to(global_position) <= explosion_radius:
			enemy.take_damage(damage)


func _draw() -> void:
	_draw_projectile_frame(1, Vector2(27, 15))


func _draw_projectile_frame(column: int, size: Vector2) -> void:
	draw_line(Vector2(-22.0, 0.0), Vector2(-5.0, 0.0), Color(1.0, 0.46, 0.16, 0.62), 3.0)
	var frame := int(visual_time * 12.0) % 2
	var cell := Vector2(PROJECTILE_ART.get_width() / 4.0, PROJECTILE_ART.get_height() / 2.0)
	var source := Rect2(Vector2(column * cell.x, frame * cell.y), cell)
	draw_texture_rect_region(PROJECTILE_ART, Rect2(-size * 0.5, size), source)


func _spawn_explosion() -> void:
	var game := get_parent().get_parent()
	if game != null and game.has_method("spawn_combat_effect"):
		var size_multiplier := 1.6 if explosion_radius > 0.0 else 1.0
		game.spawn_combat_effect(global_position, CombatEffect.Type.ROCKET_EXPLOSION, size_multiplier)
