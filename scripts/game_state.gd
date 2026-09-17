extends Node

const SAVE_PATH := "user://mechfall_progress.cfg"
const PLANET_COUNT := 5

var selected_planet := 1
var highest_unlocked_planet := 1


func _ready() -> void:
	_load_progress()


func start_new_game() -> void:
	selected_planet = 1


func select_planet(planet: int) -> void:
	selected_planet = clampi(planet, 1, highest_unlocked_planet)


func unlock_planet(planet: int) -> void:
	highest_unlocked_planet = maxi(highest_unlocked_planet, clampi(planet, 1, PLANET_COUNT))
	_save_progress()


func _load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		highest_unlocked_planet = clampi(config.get_value("progress", "highest_unlocked_planet", 1), 1, PLANET_COUNT)
		selected_planet = clampi(config.get_value("progress", "selected_planet", 1), 1, highest_unlocked_planet)


func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "highest_unlocked_planet", highest_unlocked_planet)
	config.set_value("progress", "selected_planet", selected_planet)
	config.save(SAVE_PATH)
