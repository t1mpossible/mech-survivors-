extends Control

const MENU_MUSIC_VOLUME_DB := -9.0

@onready var menu_music: AudioStreamPlayer = $MenuMusic


func _ready() -> void:
	_refresh_levels()
	_start_menu_music()


func _start_menu_music() -> void:
	var menu_theme := menu_music.stream as AudioStreamWAV
	if menu_theme == null:
		return
	menu_theme = menu_theme.duplicate() as AudioStreamWAV
	menu_theme.loop_begin = 0
	menu_theme.loop_end = roundi(menu_theme.get_length() * menu_theme.mix_rate)
	menu_theme.loop_mode = AudioStreamWAV.LOOP_FORWARD
	menu_music.stream = menu_theme
	menu_music.volume_db = MENU_MUSIC_VOLUME_DB
	menu_music.play()


func _new_game() -> void:
	GameState.start_new_game()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _show_levels() -> void:
	$MenuScale/Buttons.visible = false
	$MenuScale/Style.visible = false
	$MenuScale/LevelPanel.visible = true
	_refresh_levels()


func _hide_levels() -> void:
	$MenuScale/LevelPanel.visible = false
	$MenuScale/Buttons.visible = true
	$MenuScale/Style.visible = true


func _show_options() -> void:
	$MenuScale/Buttons.visible = false
	$MenuScale/Style.visible = false
	$MenuScale/OptionsPanel.visible = true
	var settings := _get_settings()
	if settings != null:
		$MenuScale/OptionsPanel/Volume.value = float(settings.get("master_volume")) * 100.0
		$MenuScale/OptionsPanel/Fullscreen.set_pressed_no_signal(DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN])


func _hide_options() -> void:
	$MenuScale/OptionsPanel.visible = false
	$MenuScale/Buttons.visible = true
	$MenuScale/Style.visible = true


func _set_volume(value: float) -> void:
	var settings := _get_settings()
	if settings != null:
		settings.call("set_master_volume", value / 100.0)
	$MenuScale/OptionsPanel/VolumeValue.text = "%d%%" % roundi(value)


func _set_fullscreen(enabled: bool) -> void:
	var settings := _get_settings()
	if settings != null:
		settings.call("set_fullscreen", enabled)


func _get_settings() -> Node:
	return get_node_or_null("/root/Settings")


func _refresh_levels() -> void:
	if not has_node("MenuScale/LevelPanel"):
		return
	for planet in range(1, 6):
		var button := get_node("MenuScale/LevelPanel/Zone%d" % planet) as Button
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
