extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _touch(index: int, position: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	return event


func _run() -> void:
	var stick := preload("res://scripts/virtual_joystick.gd").new() as Control
	stick.set("force_visible", true)
	stick.size = Vector2(128.0, 128.0)
	root.add_child(stick)
	stick.call("_gui_input", _touch(2, Vector2(112.0, 64.0), true))
	var direction := stick.get("direction") as Vector2
	_check(stick.visible, "Touch stick must be visible when forced for a touch device")
	_check(bool(stick.call("is_active")), "Touching the stick must activate it")
	_check(direction.x > 0.8 and absf(direction.y) < 0.05, "Stick must report the dragged direction")
	stick.call("_gui_input", _touch(2, Vector2(112.0, 64.0), false))
	_check(not bool(stick.call("is_active")), "Releasing the stick must clear movement")

	root.get_node("GameState").selected_planet = 1
	var game := load("res://scenes/main.tscn").instantiate() as Node2D
	root.add_child(game)
	game.set_process(false)
	var game_stick := game.get_node("Hud/HudScale/VirtualJoystick") as Control
	game_stick.set("touch_index", 0)
	game_stick.set("direction", Vector2.RIGHT)
	var start_position := game.get("mech_position") as Vector2
	game.call("_process", 0.5)
	var moved_position := game.get("mech_position") as Vector2
	_check(moved_position.x > start_position.x, "Main scene must use touch-stick movement")
	game.queue_free()
	stick.queue_free()
	await process_frame
	print("PASS: touch stick direction and main-scene movement" if failures == 0 else "FAIL: %d touch-stick checks" % failures)
	quit(0 if failures == 0 else 1)
