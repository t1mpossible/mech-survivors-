class_name HunterLauncher
extends Node

signal fired
signal missile_requested(start_position: Vector2, target: AlienScout, damage: int, speed: float, explosion_radius: float, blast_count: int, blast_pause: float, arc_offset: float, style: String)

@export_group("Таблицы уровней")
@export var swarm_levels: Array[HunterLevelData] = []
@export var siege_levels: Array[HunterLevelData] = []

@export_group("Первый выстрел")
@export_range(0.0, 5.0, 0.1) var first_shot_delay := 0.2

var unlocked := false
var level := 0
var branch := ""
var time_to_shot := 1.5


func unlock() -> void:
	if unlocked:
		return
	unlocked = true
	level = 1
	time_to_shot = first_shot_delay


func choose_branch(which: String) -> bool:
	if not unlocked or level != 1 or not branch.is_empty() or (which != "swarm" and which != "siege"):
		return false
	branch = which
	level = 2
	return true


func upgrade() -> bool:
	if branch.is_empty() or level >= 7:
		return false
	level += 1
	return true


func current_stats() -> HunterLevelData:
	if not unlocked:
		return null
	var entries := siege_levels if branch == "siege" else swarm_levels
	if entries.size() < level:
		return null
	return entries[level - 1]


func next_upgrade_title(which: String = "") -> String:
	var selected_branch := which if not which.is_empty() else branch
	var next_level := 2 if level == 1 else level + 1
	var entries := siege_levels if selected_branch == "siege" else swarm_levels
	if next_level < 2 or next_level > entries.size():
		return "РАКЕТЫ: МАКСИМАЛЬНЫЙ УРОВЕНЬ"
	var stats := entries[next_level - 1]
	if selected_branch == "siege":
		if next_level == 7:
			return "ТРОЙНОЙ УДАР: 3 ВЗРЫВА"
		return "ОСАДА %d: %d УР., %d ВЗР." % [next_level, stats.damage, stats.blasts]
	if next_level == 7:
		return "ЖЁЛТАЯ БУРЯ: 6 РАКЕТ"
	return "РОЙ %d: %d РАКЕТ, %d УР." % [next_level, stats.count, stats.damage]


func tick(delta: float, mech_position: Vector2, target: AlienScout, fire_rate_boost: float = 1.0) -> void:
	if not unlocked:
		return
	time_to_shot -= delta
	if time_to_shot <= 0.0 and is_instance_valid(target):
		var stats := current_stats()
		if stats == null:
			return
		for index in range(stats.count):
			var arc_offset := 0.0
			if branch == "swarm":
				arc_offset = (float(index) - float(stats.count - 1) * 0.5) * 42.0
			missile_requested.emit(mech_position + Vector2(-4.0, -9.0), target, stats.damage, stats.speed, stats.radius, stats.blasts, stats.blast_pause, arc_offset, branch)
		fired.emit()
		time_to_shot = stats.interval / maxf(fire_rate_boost, 0.01)
