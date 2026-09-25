class_name LaserWeapon
extends Node

signal damage_requested(enemy: AlienScout, amount: int)
signal fired

const BURN_DURATION := 3.5
const BURN_COOLDOWN := 1.0
const PULSE_COOLDOWN := 3.0
const PULSE_RANGE := 300.0
const PULSE_VISUAL_TIME := 1.0
const PULSE_VISUAL_FRAMES := 3

@export_group("Таблицы уровней")
@export var burn_levels: Array[LaserLevelData] = []
@export var pulse_levels: Array[LaserLevelData] = []

var unlocked := false
var level := 0
var branch := ""
var time_to_damage := 0.0
var active_time_left := 0.0
var cooldown_time_left := 0.0
var beam_time_left := 0.0
var beam_start := Vector2.ZERO
var beam_end := Vector2.ZERO
var current_target: AlienScout
var beam_active := false


func unlock() -> void:
	if unlocked:
		return
	unlocked = true
	level = 1
	time_to_damage = 0.0


func choose_branch(which: String) -> bool:
	if not unlocked or level != 1 or not branch.is_empty() or (which != "burn" and which != "pulse"):
		return false
	branch = which
	level = 2
	time_to_damage = 0.0
	cooldown_time_left = 0.0
	active_time_left = BURN_DURATION
	return true


func upgrade() -> bool:
	if branch.is_empty() or level >= 7:
		return false
	level += 1
	return true


func current_stats() -> LaserLevelData:
	if not unlocked:
		return null
	var entries := pulse_levels if branch == "pulse" else burn_levels
	if entries.size() < level:
		return null
	return entries[level - 1]


func next_upgrade_title(which: String = "") -> String:
	var selected_branch := which if not which.is_empty() else branch
	var next_level := 2 if level == 1 else level + 1
	var entries := pulse_levels if selected_branch == "pulse" else burn_levels
	if next_level < 2 or next_level > entries.size():
		return "ЛАЗЕР: МАКСИМАЛЬНЫЙ УРОВЕНЬ"
	var stats := entries[next_level - 1]
	if selected_branch == "pulse":
		return "ИМПУЛЬС %d: %d УР. ВСЕМ НА ЛИНИИ" % [next_level, stats.damage]
	return "ПРОЖИГАНИЕ %d: %d УР. КАЖДЫЕ 0,25 С" % [next_level, stats.damage]


func pulse_visual_frame() -> int:
	if branch != "pulse" or beam_time_left <= 0.0:
		return -1
	var elapsed := PULSE_VISUAL_TIME - beam_time_left
	return mini(int(elapsed / (PULSE_VISUAL_TIME / float(PULSE_VISUAL_FRAMES))), PULSE_VISUAL_FRAMES - 1)


func tick(delta: float, origin: Vector2, suggested_target: AlienScout, fire_rate_boost: float = 1.0) -> void:
	beam_time_left = maxf(beam_time_left - delta, 0.0)
	if not unlocked:
		return
	var stats := current_stats()
	if stats == null:
		return
	if branch == "pulse":
		_tick_pulse(delta, origin, suggested_target, stats, fire_rate_boost)
		return
	if branch == "burn" and cooldown_time_left > 0.0:
		cooldown_time_left = maxf(cooldown_time_left - delta, 0.0)
		beam_active = false
		current_target = null
		if cooldown_time_left <= 0.0:
			active_time_left = BURN_DURATION
			time_to_damage = 0.0
		return
	var active_delta := minf(delta, active_time_left) if branch == "burn" else delta
	current_target = _find_target(origin, suggested_target)
	beam_active = is_instance_valid(current_target)
	if beam_active:
		time_to_damage -= active_delta
		var ticks_this_frame := 0
		while time_to_damage < 0.0 and ticks_this_frame < 32:
			damage_requested.emit(current_target, stats.damage)
			time_to_damage += stats.tick_interval / maxf(fire_rate_boost, 0.01)
			ticks_this_frame += 1
	else:
		time_to_damage = 0.0
	if branch == "burn":
		active_time_left -= active_delta
		if active_time_left <= 0.0:
			beam_active = false
			current_target = null
			cooldown_time_left = BURN_COOLDOWN


func _tick_pulse(delta: float, origin: Vector2, suggested_target: AlienScout, stats: LaserLevelData, fire_rate_boost: float) -> void:
	beam_active = false
	current_target = null
	cooldown_time_left = maxf(cooldown_time_left - delta, 0.0)
	if cooldown_time_left > 0.0:
		return
	var target := _find_target(origin, suggested_target)
	if target == null:
		return
	beam_start = origin
	beam_end = origin + (target.global_position - origin).normalized() * PULSE_RANGE
	beam_time_left = PULSE_VISUAL_TIME
	var half_width := stats.beam_width * 0.5
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as AlienScout
		if _target_is_alive(enemy) and Geometry2D.get_closest_point_to_segment(enemy.global_position, beam_start, beam_end).distance_to(enemy.global_position) <= half_width + enemy.hit_radius:
			damage_requested.emit(enemy, stats.damage)
	fired.emit()
	cooldown_time_left = PULSE_COOLDOWN / maxf(fire_rate_boost, 0.01)


func _find_target(origin: Vector2, suggested_target: AlienScout) -> AlienScout:
	if _target_is_alive(suggested_target):
		return suggested_target
	var nearest: AlienScout
	var nearest_distance := INF
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as AlienScout
		if not _target_is_alive(enemy):
			continue
		var distance := origin.distance_squared_to(enemy.global_position)
		if distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest


func _target_is_alive(enemy: Variant) -> bool:
	return is_instance_valid(enemy) and enemy is AlienScout and enemy.is_inside_tree() and not enemy.is_queued_for_deletion() and enemy.health > 0
