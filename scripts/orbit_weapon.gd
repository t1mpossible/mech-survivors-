class_name OrbitWeapon
extends Node

signal damage_requested(enemy: AlienScout, amount: int, weapon_name: String)

@export_group("Сюрикены: уровни 1–7")
@export var shuriken_damage := PackedInt32Array([32, 41, 41, 41, 45, 55, 49])
@export var shuriken_radii := PackedFloat32Array([46, 46, 46, 55.2, 60.72, 60.72, 60.72])
@export var shuriken_counts := PackedInt32Array([2, 2, 2, 3, 3, 3, 4])
@export var base_rotation_speed := 3.484
@export var shuriken_tick_interval := 0.25
@export_group("Термобарический нагрев: уровни 2–7")
@export var heat_damage := PackedInt32Array([0, 8, 10, 10, 10, 12, 12])
@export var heat_radii := PackedFloat32Array([80, 80, 80, 96, 96, 115.2, 115.2])
@export var heat_intervals := PackedFloat32Array([0.5, 0.5, 0.5, 0.5, 0.4, 0.4, 0.4])
@export var wave_damage := 45
@export var wave_radius := 150.0
@export var wave_interval := 3.0

const WAVE_VISUAL_DURATION := 0.6
var unlocked := false
var level := 0
var branch := ""
var angle := 0.0
var time_to_hit := 0.0
var time_to_wave := 3.0
var wave_visual_time := 0.0
var wave_origin := Vector2.ZERO


func reset() -> void:
	unlocked = false
	level = 0
	branch = ""
	angle = 0.0
	time_to_hit = 0.0
	time_to_wave = wave_interval
	wave_visual_time = 0.0


func unlock() -> void:
	if not unlocked:
		unlocked = true
		level = 1
		time_to_hit = 0.0


func choose_branch(which: String) -> bool:
	if not unlocked or level != 1 or not branch.is_empty() or which not in ["shuriken", "heat"]:
		return false
	branch = which
	level = 2
	time_to_hit = 0.0
	return true


func upgrade() -> bool:
	if not unlocked or branch.is_empty() or level >= 7:
		return false
	level += 1
	if level == 7:
		time_to_wave = wave_interval
	return true


func damage() -> int:
	return heat_damage[level - 1] if branch == "heat" else shuriken_damage[maxi(level - 1, 0)]


func radius() -> float:
	return heat_radii[level - 1] if branch == "heat" else shuriken_radii[maxi(level - 1, 0)]


func count() -> int:
	return 0 if branch == "heat" else shuriken_counts[maxi(level - 1, 0)]


func angles() -> Array[float]:
	var result: Array[float] = []
	for index in range(count()):
		result.append(TAU * float(index) / float(count()))
	return result


func tick(delta: float, origin: Vector2, fire_rate_boost: float = 1.0) -> void:
	if not unlocked:
		return
	wave_visual_time = maxf(wave_visual_time - delta, 0.0)
	angle = fmod(angle + delta * base_rotation_speed * (1.2 if branch == "shuriken" and level >= 3 else 1.0), TAU)
	time_to_hit -= delta
	var interval := heat_intervals[level - 1] if branch == "heat" else shuriken_tick_interval
	var iterations := 0
	while time_to_hit < 0.0 and iterations < 32:
		var enemies := get_tree().get_nodes_in_group("enemies")
		if branch == "heat":
			_damage_area(origin, radius(), damage(), enemies)
		else:
			var hit_radius := 14.0 if level == 7 else 10.5
			for offset in angles():
				var location := origin + Vector2.from_angle(angle + offset) * radius()
				for node in enemies:
					var enemy := node as AlienScout
					if _alive(enemy) and enemy.global_position.distance_squared_to(location) <= pow(hit_radius + enemy.hit_radius, 2):
						damage_requested.emit(enemy, damage(), "СЮРИКЕНЫ")
		time_to_hit += interval / maxf(fire_rate_boost, 0.01)
		iterations += 1
	if branch == "heat" and level == 7:
		time_to_wave -= delta
		if time_to_wave <= 0.0:
			wave_origin = origin
			wave_visual_time = WAVE_VISUAL_DURATION
			_damage_area(origin, wave_radius, wave_damage, get_tree().get_nodes_in_group("enemies"))
			time_to_wave += wave_interval


func _damage_area(origin: Vector2, area_radius: float, amount: int, enemies: Array[Node]) -> void:
	for node in enemies:
		var enemy := node as AlienScout
		if _alive(enemy) and enemy.global_position.distance_squared_to(origin) <= area_radius * area_radius:
			damage_requested.emit(enemy, amount, "ТЕРМОБАРИЧЕСКИЙ НАГРЕВ")


func _alive(enemy: Variant) -> bool:
	return is_instance_valid(enemy) and enemy is AlienScout and not enemy.is_queued_for_deletion() and enemy.health > 0


func next_upgrade_title(which: String = "") -> String:
	var path := branch if which.is_empty() else which
	var next_level := level + 1
	if next_level > 7:
		return "МАКСИМАЛЬНЫЙ УРОВЕНЬ"
	if path == "heat":
		return ["", "", "НАГРЕВ: 8 УРОНА КАЖДЫЕ 0,5 С", "НАГРЕВ: +25% УРОНА", "НАГРЕВ: +20% РАДИУСА", "НАГРЕВ: УРОН КАЖДЫЕ 0,4 С", "НАГРЕВ: +20% УРОНА И РАДИУСА", "ПЕРЕГРЕВ ЯДРА: ТЕПЛОВАЯ ВОЛНА"][next_level]
	if next_level == 7:
		return "ОРБИТАЛЬНАЯ МЯСОРУБКА: 4 × %d" % shuriken_damage[6]
	return ["", "", "СЮРИКЕНЫ: +25% УРОНА", "СЮРИКЕНЫ: +20% ВРАЩЕНИЕ", "СЮРИКЕНЫ: ТРЕТИЙ, +20% РАДИУСА", "СЮРИКЕНЫ: +10% УРОНА И РАДИУСА", "СЮРИКЕНЫ: +25% УРОНА"][next_level]
