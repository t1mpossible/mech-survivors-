class_name PlasmaRound
extends Node2D

const SPEED := 150.0
const HOMING_TIME := 0.8
const ORPHAN_FLIGHT_TIME := 4.5
const PROJECTILE_ART := preload("res://assets/projectiles_v1.png")

var target: AlienScout
var damage := 10
var active := false
var visual_time := 0.0
var travel_direction := Vector2.RIGHT
var guidance_time_left := HOMING_TIME
var spread_angle := 0.0
var target_was_alive := false
var flight_speed := SPEED
var flight_time_left := ORPHAN_FLIGHT_TIME
var prime_round := false
var heavy_round := false
var pierce_limit := 1
var penetrated_enemy_ids: Array[int] = []


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	queue_redraw()


func activate(start_position: Vector2, new_target: AlienScout, new_damage: int, spread_direction: Vector2 = Vector2.ZERO, speed_multiplier: float = 1.0, is_prime: bool = false, is_heavy: bool = false, new_pierce_limit: int = 1) -> void:
	global_position = start_position
	target = new_target
	damage = new_damage
	visual_time = 0.0
	guidance_time_left = HOMING_TIME
	target_was_alive = is_instance_valid(target)
	flight_speed = SPEED * speed_multiplier
	heavy_round = is_heavy
	pierce_limit = maxi(new_pierce_limit, 1)
	penetrated_enemy_ids.clear()
	flight_time_left = 7.0 if heavy_round and pierce_limit > 1 else ORPHAN_FLIGHT_TIME
	prime_round = is_prime
	spread_angle = 0.0
	if target_was_alive:
		travel_direction = (target.global_position - global_position).normalized()
	if spread_direction != Vector2.ZERO:
		spread_angle = travel_direction.angle_to(spread_direction)
		travel_direction = spread_direction.normalized()
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
	if target_was_alive and (not is_instance_valid(target) or target.health <= 0):
		target_was_alive = false
		target = null
		guidance_time_left = 0.0
		if not heavy_round:
			flight_time_left = ORPHAN_FLIGHT_TIME
	if guidance_time_left > 0.0 and target_was_alive:
		var guided_delta := minf(delta, guidance_time_left)
		var aim := (target.global_position - global_position).normalized()
		if aim != Vector2.ZERO:
			travel_direction = aim.rotated(spread_angle)
			rotation = travel_direction.angle()
		guidance_time_left -= guided_delta
		_advance_round(guided_delta)
		if active and delta > guided_delta:
			_advance_round(delta - guided_delta)
	else:
		_advance_round(delta)


func _advance_round(delta: float) -> void:
	var start_position := global_position
	var end_position := start_position + travel_direction * flight_speed * delta
	var impacts: Array[Dictionary] = []
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		if heavy_round and penetrated_enemy_ids.size() >= pierce_limit:
			break
		var enemy := enemy_node as AlienScout
		if enemy == null or enemy.health <= 0 or penetrated_enemy_ids.has(enemy.get_instance_id()):
			continue
		var closest := Geometry2D.get_closest_point_to_segment(enemy.global_position, start_position, end_position)
		var collision_radius := enemy.hit_radius + (7.0 if heavy_round else 4.0)
		if closest.distance_squared_to(enemy.global_position) > collision_radius * collision_radius:
			continue
		impacts.append({"enemy": enemy, "distance": start_position.distance_squared_to(closest)})
	impacts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.distance < b.distance)
	for impact in impacts:
		var hit_enemy := impact.enemy as AlienScout
		if not is_instance_valid(hit_enemy) or hit_enemy.health <= 0:
			continue
		global_position = start_position + travel_direction * sqrt(impact.distance)
		_spawn_impact()
		var game := get_parent().get_parent()
		if game != null and game.has_method("_deal_weapon_damage"):
			game._deal_weapon_damage(hit_enemy, damage, "АВТОПУШКА")
		else:
			hit_enemy.take_damage(damage)
		penetrated_enemy_ids.append(hit_enemy.get_instance_id())
		if penetrated_enemy_ids.size() >= pierce_limit:
			if not heavy_round:
				deactivate()
				return
			guidance_time_left = 0.0
			target_was_alive = false
			target = null
			break
		# A piercing hit ends guidance immediately. Keep the current direction and
		# continue past the enemy instead of turning back toward the same target.
		guidance_time_left = 0.0
		target_was_alive = false
		target = null
	global_position = end_position
	flight_time_left -= delta
	if flight_time_left <= 0.0:
		deactivate()
	else:
		queue_redraw()


func _draw() -> void:
	if heavy_round:
		draw_line(Vector2(-28.0, 0.0), Vector2(-3.0, 0.0), Color(1.0, 0.42, 0.12, 0.3), 8.0)
		draw_line(Vector2(-27.0, 0.0), Vector2(-3.0, 0.0), Color(1.0, 0.78, 0.35, 0.75), 3.0)
	if prime_round:
		draw_line(Vector2(-20.0, 0.0), Vector2(-3.0, 0.0), Color(0.25, 0.82, 1.0, 0.25), 7.0)
		draw_line(Vector2(-18.0, 0.0), Vector2(-2.0, 0.0), Color(0.75, 0.96, 1.0, 0.85), 2.0)
	_draw_projectile_frame(0, Vector2(32, 15) if heavy_round else Vector2(20, 11))


func _draw_projectile_frame(column: int, size: Vector2) -> void:
	draw_line(Vector2(-14.0, 0.0), Vector2(-3.0, 0.0), Color(0.25, 0.82, 1.0, 0.45), 2.0)
	var frame := int(visual_time * 12.0) % 2
	var cell := Vector2(PROJECTILE_ART.get_width() / 4.0, PROJECTILE_ART.get_height() / 2.0)
	var source := Rect2(Vector2(column * cell.x, frame * cell.y), cell)
	draw_texture_rect_region(PROJECTILE_ART, Rect2(-size * 0.5, size), source, Color("ffcc85") if heavy_round else Color.WHITE)


func _spawn_impact() -> void:
	var game := get_parent().get_parent()
	if game != null and game.has_method("spawn_combat_effect"):
		game.spawn_combat_effect(global_position, CombatEffect.Type.PLASMA_IMPACT)
