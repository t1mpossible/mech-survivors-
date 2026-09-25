class_name HunterMissile
extends Node2D

const BASE_SPEED := 95.0
const ORPHAN_FLIGHT_TIME := 4.5
const PROJECTILE_ART := preload("res://assets/projectiles_v1.png")

@export_group("Плавное наведение")
@export_range(30.0, 360.0, 5.0) var turn_degrees_per_second := 100.0
@export_range(5.0, 30.0, 1.0) var maximum_guided_flight_time := 8.0

var target: AlienScout
var damage := 20
var speed := BASE_SPEED
var explosion_radius := 0.0
var blast_count := 1
var blast_pause := 0.0
var blasts_left := 0
var blast_time_left := 0.0
var exploding := false
var arc_offset := 0.0
var launch_direction := Vector2.RIGHT
var missile_style := ""
var active := false
var visual_time := 0.0
var travel_direction := Vector2.RIGHT
var orphan_flight_time := 0.0
var guided_flight_time_left := 0.0


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	queue_redraw()


func activate(start_position: Vector2, new_target: AlienScout, new_damage: int, new_speed: float = BASE_SPEED, new_explosion_radius: float = 0.0, new_blast_count: int = 1, new_blast_pause: float = 0.0, new_arc_offset: float = 0.0, new_style: String = "") -> void:
	global_position = start_position
	target = new_target
	damage = new_damage
	speed = new_speed
	explosion_radius = new_explosion_radius
	blast_count = maxi(new_blast_count, 1)
	blast_pause = maxf(new_blast_pause, 0.0)
	blasts_left = 0
	blast_time_left = 0.0
	exploding = false
	arc_offset = new_arc_offset
	missile_style = new_style
	visual_time = 0.0
	orphan_flight_time = 0.0
	guided_flight_time_left = maximum_guided_flight_time
	travel_direction = Vector2.RIGHT
	launch_direction = travel_direction
	if is_instance_valid(target):
		travel_direction = (target.global_position - global_position).normalized()
		launch_direction = travel_direction
		rotation = travel_direction.angle()
	active = true
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT


func deactivate() -> void:
	active = false
	visible = false
	target = null
	exploding = false
	blasts_left = 0
	process_mode = Node.PROCESS_MODE_DISABLED


func _process(delta: float) -> void:
	visual_time += delta
	if exploding:
		blast_time_left -= delta
		if blast_time_left <= 0.0:
			_explode()
			blasts_left -= 1
			if blasts_left <= 0:
				deactivate()
			else:
				blast_time_left += maxf(blast_pause, 0.01)
		return
	if orphan_flight_time > 0.0:
		global_position += travel_direction * speed * delta
		orphan_flight_time -= delta
		if orphan_flight_time <= 0.0:
			deactivate()
		else:
			queue_redraw()
		return
	guided_flight_time_left -= delta
	if guided_flight_time_left <= 0.0:
		_detonate_on_timeout()
		return
	if not _target_is_alive(target):
		target = _find_replacement_target()
		if target == null:
			_begin_orphan_flight()
			return
		launch_direction = (target.global_position - global_position).normalized()
		arc_offset = 0.0

	var offset := target.global_position - global_position
	var hit_radius := target.hit_radius + 4.0
	if offset.length() <= hit_radius:
		_impact()
		return

	var aim_position := target.global_position
	if not is_zero_approx(arc_offset):
		var arc_remaining := maxf(1.0 - visual_time / 1.15, 0.0)
		aim_position += launch_direction.orthogonal() * arc_offset * arc_remaining
	var desired_direction := (aim_position - global_position).normalized()
	var maximum_turn := deg_to_rad(turn_degrees_per_second) * delta
	var turn := clampf(travel_direction.angle_to(desired_direction), -maximum_turn, maximum_turn)
	travel_direction = travel_direction.rotated(turn).normalized()
	var next_position := global_position + travel_direction * speed * delta
	if Geometry2D.get_closest_point_to_segment(target.global_position, global_position, next_position).distance_to(target.global_position) <= hit_radius:
		global_position = target.global_position
		_impact()
		return
	global_position = next_position
	rotation = travel_direction.angle()
	queue_redraw()


func _impact() -> void:
	_explode()
	if blast_count > 1:
		exploding = true
		blasts_left = blast_count - 1
		blast_time_left = maxf(blast_pause, 0.01)
		visible = false
		target = null
	else:
		deactivate()


func _detonate_on_timeout() -> void:
	if explosion_radius > 0.0 or (_target_is_alive(target) and global_position.distance_to(target.global_position) <= target.hit_radius + 4.0):
		_impact()
	else:
		_spawn_explosion()
		deactivate()


func _begin_orphan_flight() -> void:
	target = null
	orphan_flight_time = ORPHAN_FLIGHT_TIME
	queue_redraw()


func _target_is_alive(enemy: Variant) -> bool:
	return is_instance_valid(enemy) and enemy is AlienScout and enemy.is_inside_tree() and not enemy.is_queued_for_deletion() and enemy.health > 0


func _find_replacement_target() -> AlienScout:
	var nearest: AlienScout
	var nearest_distance := INF
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as AlienScout
		if not _target_is_alive(enemy):
			continue
		var distance := global_position.distance_squared_to(enemy.global_position)
		if distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest


func _explode() -> void:
	_spawn_explosion()
	var game := get_parent().get_parent()
	if explosion_radius <= 0.0:
		if game != null and game.has_method("_deal_weapon_damage"):
			game._deal_weapon_damage(target, damage, "ОХОТНИЧЬИ РАКЕТЫ")
		else:
			target.take_damage(damage)
		return
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as AlienScout
		if enemy != null and enemy.global_position.distance_to(global_position) <= explosion_radius:
			if game != null and game.has_method("_deal_weapon_damage"):
				game._deal_weapon_damage(enemy, damage, "ОХОТНИЧЬИ РАКЕТЫ")
			else:
				enemy.take_damage(damage)


func _draw() -> void:
	if missile_style == "swarm":
		_draw_projectile_frame(1, Vector2(19, 10), Color("ffe168"))
	elif missile_style == "siege":
		_draw_projectile_frame(1, Vector2(36, 20), Color("ffaf69"))
	else:
		_draw_projectile_frame(1, Vector2(27, 15), Color.WHITE)


func _draw_projectile_frame(column: int, size: Vector2, tint: Color) -> void:
	var trail_color := Color(1.0, 0.87, 0.3, 0.7) if missile_style == "swarm" else Color(1.0, 0.46, 0.16, 0.62)
	draw_line(Vector2(-size.x * 0.8, 0.0), Vector2(-size.x * 0.2, 0.0), trail_color, 3.0)
	var frame := int(visual_time * 12.0) % 2
	var cell := Vector2(PROJECTILE_ART.get_width() / 4.0, PROJECTILE_ART.get_height() / 2.0)
	var source := Rect2(Vector2(column * cell.x, frame * cell.y), cell)
	draw_texture_rect_region(PROJECTILE_ART, Rect2(-size * 0.5, size), source, tint)


func _spawn_explosion() -> void:
	var game := get_parent().get_parent()
	if game != null and game.has_method("spawn_combat_effect"):
		var size_multiplier := 1.6 if explosion_radius > 0.0 else 1.0
		game.spawn_combat_effect(global_position, CombatEffect.Type.ROCKET_EXPLOSION, size_multiplier)
