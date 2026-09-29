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


func _show_options() -> void:
	$Buttons.visible = false
	$Style.visible = false
	$OptionsPanel.visible = true
	var settings := _get_settings()
	if settings != null:
		$OptionsPanel/Volume.value = float(settings.get("master_volume")) * 100.0
		$OptionsPanel/Fullscreen.button_pressed = bool(settings.get("fullscreen"))


func _hide_options() -> void:
	$OptionsPanel.visible = false
	$Buttons.visible = true
	$Style.visible = true


func _set_volume(value: float) -> void:
	var settings := _get_settings()
	if settings != null:
		settings.call("set_master_volume", value / 100.0)
	$OptionsPanel/VolumeValue.text = "%d%%" % roundi(value)


func _set_fullscreen(enabled: bool) -> void:
	var settings := _get_settings()
	if settings != null:
		settings.call("set_fullscreen", enabled)


func _get_settings() -> Node:
	return get_node_or_null("/root/Settings")


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


func _exit_game() -> void:
	get_tree().quit()


func _select_test_arena() -> void:
	get_tree().change_scene_to_file("res://scenes/test_arena.tscn")
