extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := load("res://scenes/main.tscn").instantiate() as Node2D
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.planet_number = 1
	game._update_wave_selector()
	assert(game.get_node("Hud/HudScale/Wave1").visible)
	assert(game.get_node("Hud/HudScale/Wave6").visible)
	game.get_node("Hud/HudScale/Wave4").emit_signal("pressed")
	assert(game.wave_number == 4)
	assert(is_zero_approx(game.wave_elapsed))
	game.planet_number = 2
	game._update_wave_selector()
	assert(not game.get_node("Hud/HudScale/Wave1").visible)
	assert(not game.get_node("Hud/HudScale/Wave6").visible)
	print("PASS: compact wave selector switches first-planet waves and hides outside zone 1")
	quit()
