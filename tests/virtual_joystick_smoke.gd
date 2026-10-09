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
	var view := SubViewport.new()
	view.size = Vector2i(844, 390)
	view.size_2d_override = Vector2i(779, 360)
	view.size_2d_override_stretch = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var hud := Control.new()
	hud.position = Vector2(25, 12)
	hud.scale = Vector2.ONE * 0.9
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.add_child(hud)
	var stick := preload("res://scripts/virtual_joystick.gd").new() as Control
	stick.set("force_visible", true)
	stick.size = Vector2(779, 360)
	hud.add_child(stick)
	await process_frame
	_check(not stick.visible, "Floating stick must be hidden before touching")
	for origin in [Vector2(160, 220), Vector2(580, 170)]:
		for step in range(8):
			var expected := Vector2.RIGHT.rotated(step * PI / 4.0)
			var transform := stick.get_global_transform_with_canvas()
			view.push_input(_touch(2, transform * origin, true), true)
			_check(stick.visible, "Touch in either half must show stick")
			_check((stick.get("direction") as Vector2).is_zero_approx(), "Initial touch must not move mech")
			var drag := InputEventScreenDrag.new()
			drag.index = 2
			drag.position = transform * (origin + expected * 60)
			view.push_input(drag, true)
			_check((stick.get("direction") as Vector2).is_equal_approx(expected), "Wrong direction with scaled, offset HUD: %s" % expected)
			view.push_input(_touch(3, Vector2(700, 120), false), true)
			_check(bool(stick.call("is_active")), "Other finger must not release movement")
			view.push_input(_touch(2, drag.position, false), true)
			_check(not stick.visible and not bool(stick.call("is_active")), "Release must hide and stop stick")
	view.push_input(_touch(2, Vector2(240, 240), true), true)
	paused = true
	await process_frame
	await process_frame
	_check(not stick.visible and stick.get("touch_index") == -1, "Pause must release held touch")
	paused = false
	var button := Button.new()
	button.position = Vector2(200, 100)
	button.size = Vector2(160, 60)
	view.add_child(button)
	view.push_input(_touch(1, Vector2(220, 120), true), true)
	_check(not stick.visible, "Touch on GUI button must not activate stick")
	view.push_input(_touch(1, Vector2(220, 120), false), true)
	button.queue_free()
	hud.queue_free()
	await process_frame

	root.get_node("GameState").selected_planet = 1
	var game := load("res://scenes/main.tscn").instantiate() as Node2D
	game.get_node("Hud/HudScale/VirtualJoystick").set("force_visible", true)
	view.add_child(game)
	game.set_process(false)
	_check(game.get_node("Camera2D").zoom == Vector2(1.5, 1.5), "Touch camera must be closer")
	var game_stick := game.get_node("Hud/HudScale/VirtualJoystick") as Control
	game_stick.set("touch_index", 0)
	game_stick.set("direction", Vector2.RIGHT)
	var start_position := game.get("mech_position") as Vector2
	game.call("_process", 0.5)
	var moved_position := game.get("mech_position") as Vector2
	_check(moved_position.x > start_position.x, "Main scene must use touch-stick movement")
	game.get_node("Hud/HudScale").set("touch_layout", true)
	game.get_node("Hud/HudScale").call("_apply_layout")
	game.call("_position_camera")
	for frame in range(4):
		await process_frame
	_check(game.get_node("Hud/HudScale").scale.x > 1.15, "Phone landscape HUD should use extra width for larger UI")
	game_stick.call("_release_touch")
	view.push_input(_touch(0, Vector2(150, 250), true), true)
	var capture_drag := InputEventScreenDrag.new()
	capture_drag.index = 0
	capture_drag.position = Vector2(190, 225)
	view.push_input(capture_drag, true)
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		view.get_texture().get_image().save_png("res://.godot/mobile_stick_preview.png")
	game.queue_free()
	view.queue_free()
	await process_frame
	print("PASS: touch stick direction and main-scene movement" if failures == 0 else "FAIL: %d touch-stick checks" % failures)
	quit(0 if failures == 0 else 1)
