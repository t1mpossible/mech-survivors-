class_name Autocannon
extends Node

signal fired
signal projectile_requested(start_position: Vector2, target: AlienScout, damage: int, direction: Vector2, speed_multiplier: float, prime: bool, heavy: bool, pierce_limit: int)

@export_group("Базовая автопушка")
@export_range(1.0, 200.0, 1.0) var base_damage := 18.0
@export_range(0.1, 5.0, 0.05) var base_shot_interval := 1.5

@export_group("Веер: уровни 2–4")
@export_range(1, 8, 1) var fan_level_2_projectiles := 2
@export_range(0.1, 2.0, 0.01) var fan_level_2_damage_multiplier := 0.65
@export_range(0.1, 3.0, 0.01) var fan_level_3_damage_multiplier := 1.2
@export_range(0.1, 3.0, 0.01) var fan_level_3_fire_rate_multiplier := 1.2
@export_range(1, 8, 1) var fan_level_4_projectiles := 3
@export_range(0.0, 45.0, 1.0) var fan_spread_degrees := 12.0

@export_group("Веер: уровни 5–7")
@export_range(0.1, 3.0, 0.01) var fan_level_5_fire_rate_multiplier := 1.3
@export_range(0.1, 2.0, 0.01) var fan_level_5_damage_multiplier := 0.85
@export_range(0.1, 3.0, 0.01) var fan_level_6_damage_multiplier := 1.2
@export_range(0.1, 3.0, 0.01) var fan_level_6_projectile_speed_multiplier := 1.3
@export_range(0.1, 3.0, 0.01) var fan_level_7_damage_multiplier := 1.15
@export_range(0.1, 3.0, 0.01) var fan_level_7_fire_rate_multiplier := 1.35

@export_group("Тяжёлая: уровни 2–4")
@export_range(0.1, 4.0, 0.01) var heavy_level_2_damage_multiplier := 1.5
@export_range(0.1, 2.0, 0.01) var heavy_level_2_fire_rate_multiplier := 0.65
@export_range(1, 8, 1) var heavy_level_3_pierce := 2
@export_range(0.1, 3.0, 0.01) var heavy_level_3_projectile_speed_multiplier := 1.2
@export_range(0.1, 4.0, 0.01) var heavy_level_4_damage_multiplier := 1.35

@export_group("Тяжёлая: уровни 5–7")
@export_range(1, 8, 1) var heavy_level_5_pierce := 3
@export_range(0.1, 3.0, 0.01) var heavy_level_5_fire_rate_multiplier := 1.2
@export_range(0.1, 3.0, 0.01) var heavy_level_6_damage_multiplier := 1.15
@export_range(0.1, 3.0, 0.01) var heavy_level_6_fire_rate_multiplier := 1.15
@export_range(1.0, 200.0, 1.0) var desert_eagle_damage := 30.0
@export_range(1, 20, 1) var desert_eagle_burst_size := 7
@export_range(0.05, 2.0, 0.05) var desert_eagle_shot_interval := 0.2
@export_range(0.1, 10.0, 0.1) var desert_eagle_reload := 3.0

var level := 1
var branch := ""
var damage := 18.0
var shot_interval := 1.5
var projectile_count := 1
var projectile_speed_multiplier := 1.0
var pierce_limit := 1
var prime := false
var time_to_shot := 0.0
var burst_shots_left := 0
var burst_time_to_shot := 0.0
var last_direction := Vector2.RIGHT


func _ready() -> void:
	damage = base_damage
	shot_interval = base_shot_interval


func tick(delta: float, mech_position: Vector2, target: AlienScout, fire_rate_boost: float = 1.0) -> void:
	if branch == "heavy" and level == 7:
		if burst_shots_left > 0:
			burst_time_to_shot -= delta
			if burst_time_to_shot <= 0.0:
				_fire(mech_position, target)
				burst_shots_left -= 1
				burst_time_to_shot += desert_eagle_shot_interval
				if burst_shots_left == 0:
					time_to_shot = desert_eagle_reload
		else:
			time_to_shot -= delta
			if time_to_shot <= 0.0 and is_instance_valid(target):
				_fire(mech_position, target)
				burst_shots_left = desert_eagle_burst_size - 1
				burst_time_to_shot = desert_eagle_shot_interval
				if burst_shots_left == 0:
					time_to_shot = desert_eagle_reload
		return

	time_to_shot -= delta
	if time_to_shot <= 0.0 and is_instance_valid(target):
		_fire(mech_position, target)
		time_to_shot = shot_interval / maxf(fire_rate_boost, 0.01)


func _fire(mech_position: Vector2, target: AlienScout) -> void:
	var aim := last_direction
	if is_instance_valid(target):
		aim = (target.global_position - mech_position).normalized()
	if aim == Vector2.ZERO:
		aim = Vector2.RIGHT
	last_direction = aim
	fired.emit()
	for shot_index in range(projectile_count):
		var shot_offset := float(shot_index) - float(projectile_count - 1) * 0.5
		var angle_step := fan_spread_degrees if projectile_count >= 3 else fan_spread_degrees * 0.75
		var direction := aim.rotated(deg_to_rad(angle_step * shot_offset * (2.0 if projectile_count == 2 else 1.0)))
		var start_position := mech_position + aim * 13.0 + aim.orthogonal() * shot_offset * 4.0
		var spread_direction := direction if projectile_count > 1 or not is_instance_valid(target) else Vector2.ZERO
		projectile_requested.emit(start_position, target, roundi(damage), spread_direction,
			projectile_speed_multiplier, prime, branch == "heavy", pierce_limit)


func apply_upgrade(path: String) -> bool:
	if level >= 7 or (not branch.is_empty() and branch != path):
		return false
	if path != "fan" and path != "heavy":
		return false
	level += 1
	if level == 2:
		branch = path
	if path == "fan":
		_apply_fan_upgrade()
	else:
		_apply_heavy_upgrade()
	return true


func _apply_fan_upgrade() -> void:
	match level:
		2:
			projectile_count = fan_level_2_projectiles
			damage *= fan_level_2_damage_multiplier
		3:
			damage *= fan_level_3_damage_multiplier
			shot_interval /= fan_level_3_fire_rate_multiplier
		4:
			projectile_count = fan_level_4_projectiles
		5:
			shot_interval /= fan_level_5_fire_rate_multiplier
			damage *= fan_level_5_damage_multiplier
		6:
			damage *= fan_level_6_damage_multiplier
			projectile_speed_multiplier *= fan_level_6_projectile_speed_multiplier
		7:
			damage *= fan_level_7_damage_multiplier
			shot_interval /= fan_level_7_fire_rate_multiplier
			prime = true


func _apply_heavy_upgrade() -> void:
	match level:
		2:
			damage *= heavy_level_2_damage_multiplier
			shot_interval /= heavy_level_2_fire_rate_multiplier
		3:
			pierce_limit = heavy_level_3_pierce
			projectile_speed_multiplier *= heavy_level_3_projectile_speed_multiplier
		4:
			damage *= heavy_level_4_damage_multiplier
		5:
			pierce_limit = heavy_level_5_pierce
			shot_interval /= heavy_level_5_fire_rate_multiplier
		6:
			damage *= heavy_level_6_damage_multiplier
			shot_interval /= heavy_level_6_fire_rate_multiplier
		7:
			damage = desert_eagle_damage
			time_to_shot = 0.0


func next_upgrade_title(path: String) -> String:
	if path == "heavy":
		match level:
			1:
				return "ТЯЖ. УР. 2: +%d%% УРОН, -%d%% ТЕМП" % [roundi((heavy_level_2_damage_multiplier - 1.0) * 100.0), roundi((1.0 - heavy_level_2_fire_rate_multiplier) * 100.0)]
			2:
				return "ТЯЖ. УР. 3: ПРОБИТИЕ %d, +%d%% СКОР." % [heavy_level_3_pierce, roundi((heavy_level_3_projectile_speed_multiplier - 1.0) * 100.0)]
			3:
				return "ТЯЖ. УР. 4: +%d%% УРОН" % roundi((heavy_level_4_damage_multiplier - 1.0) * 100.0)
			4:
				return "ТЯЖ. УР. 5: ПРОБИТИЕ %d, +%d%% ТЕМП" % [heavy_level_5_pierce, roundi((heavy_level_5_fire_rate_multiplier - 1.0) * 100.0)]
			5:
				return "ТЯЖ. УР. 6: +%d%% УРН, +%d%% ТЕМП" % [roundi((heavy_level_6_damage_multiplier - 1.0) * 100.0), roundi((heavy_level_6_fire_rate_multiplier - 1.0) * 100.0)]
			6:
				return "УР. 7: DESERT EAGLE — ОЧЕРЕДЬ ИЗ %d" % desert_eagle_burst_size
	else:
		match level:
			1:
				return "ПУШКА УР. 2: %d СНАРЯДА, -%d%% УРОН" % [fan_level_2_projectiles, roundi((1.0 - fan_level_2_damage_multiplier) * 100.0)]
			2:
				return "ПУШКА УР. 3: +%d%% УРН, +%d%% ТЕМП" % [roundi((fan_level_3_damage_multiplier - 1.0) * 100.0), roundi((fan_level_3_fire_rate_multiplier - 1.0) * 100.0)]
			3:
				return "ПУШКА УР. 4: %d СНАРЯДА ВЕЕРОМ" % fan_level_4_projectiles
			4:
				return "ПУШКА УР. 5: +%d%% ТЕМП, -%d%% УРОН" % [roundi((fan_level_5_fire_rate_multiplier - 1.0) * 100.0), roundi((1.0 - fan_level_5_damage_multiplier) * 100.0)]
			5:
				return "ПУШКА УР. 6: +%d%% УРОН, +%d%% СКОР." % [roundi((fan_level_6_damage_multiplier - 1.0) * 100.0), roundi((fan_level_6_projectile_speed_multiplier - 1.0) * 100.0)]
			6:
				return "УР. 7: ПЛАЗМОТРОН ПРАЙМ"
	return "АВТОПУШКА: МАКСИМАЛЬНЫЙ УРОВЕНЬ"
