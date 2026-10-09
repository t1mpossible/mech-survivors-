extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func settle() -> void:
	# Allow native window events and the deferred safe-area/camera layout to arrive.
	await create_timer(0.3, true).timeout
	await process_frame


func check_layout(game: Node, label: String) -> void:
	var hud: Control = game.get_node("Hud/HudScale")
	var viewport_size := root.get_visible_rect().size
	if not hud.size.is_equal_approx(viewport_size):
		failures += 1
		push_error("HUD differs from actual window viewport: " + label)
	if not hud.get_node("UpgradePanel").get_rect().get_center().is_equal_approx(viewport_size * 0.5):
		failures += 1
		push_error("Upgrade not centered: " + label)
	if (root.canvas_transform * game.mech_position).distance_to(viewport_size * 0.5) > 1.0:
		failures += 1
		push_error("Camera drift while paused: " + label)
	print("%s: window=%s viewport=%s" % [label, root.size, viewport_size])


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Run this test with a graphical renderer")
		quit(1)
		return
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	await settle()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game._position_camera()
	game._open_upgrade_choice()
	await settle()
	check_layout(game, "1280x720 paused")
	root.size = Vector2i(1000, 700)
	await settle()
	check_layout(game, "1000x700 paused")
	root.mode = Window.MODE_FULLSCREEN
	await settle()
	check_layout(game, "Fullscreen paused")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/scaling_native_fullscreen.png")
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	await settle()
	check_layout(game, "Return to window paused")
	# Click through the real viewport GUI dispatch after mode switching.
	var button: Button = game.get_node("Hud/HudScale/UpgradePanel/OptionA")
	var press := InputEventMouseButton.new()
	press.position = button.get_global_rect().get_center()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	root.push_input(press, true)
	var release := press.duplicate() as InputEventMouseButton
	release.pressed = false
	root.push_input(release, true)
	await settle()
	if game.upgrade_open or paused:
		failures += 1
		push_error("Upgrade button does not accept clicks after resize")
	paused = false
	game.queue_free()
	await process_frame
	print("Native window/fullscreen: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)
