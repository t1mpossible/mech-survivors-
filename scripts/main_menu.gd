extends Control


func _ready() -> void:
	_refresh_levels()


func _new_game() -> void:
	GameState.start_new_game()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _show_levels() -> void:
	$Buttons.visible = false
	$Style.visible = false
	$LevelPanel.visible = true
	_refresh_levels()


func _hide_levels() -> void:
	$LevelPanel.visible = false
	$Buttons.visible = true
	$Style.visible = true


func _refresh_levels() -> void:
	if not has_node("LevelPanel"):
		return
	for planet in range(1, 6):
		var button := get_node("LevelPanel/Zone%d" % planet) as Button
		var unlocked := planet <= GameState.highest_unlocked_planet
		button.disabled = not unlocked
		button.text = "ЗОНА %d" % planet if unlocked else "ЗОНА %d — ЗАКРЫТО" % planet


func _select_level(planet: int) -> void:
	if planet <= GameState.highest_unlocked_planet:
		GameState.select_planet(planet)
		get_tree().change_scene_to_file("res://scenes/main.tscn")


func _coming_soon() -> void:
	$Style.text = "ОПЦИИ ПОЯВЯТСЯ ПОЗЖЕ"

func _exit_game() -> void:
	get_tree().quit()
