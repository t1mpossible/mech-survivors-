extends SceneTree

const SIZES := [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1440),
	Vector2i(1280, 800), Vector2i(1024, 768), Vector2i(2340, 1080),
	Vector2i(844, 390), Vector2i(390, 844)]
var failures := 0
var capture := false


func _initialize() -> void:
	call_deferred("_run")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func settle() -> void:
	for frame in range(4):
		await process_frame


func resize_view(view: SubViewport, pixels: Vector2i) -> void:
	view.size = pixels
	var factor := minf(pixels.x / 640.0, pixels.y / 360.0)
	view.size_2d_override = Vector2i(Vector2(pixels) / factor)
	view.size_2d_override_stretch = true
	await settle()


func screenshot(view: SubViewport, label: String) -> void:
	if not capture:
		return
	await RenderingServer.frame_post_draw
	check(view.get_texture().get_image().save_png("res://.godot/scaling_%s.png" % label) == OK, "Screenshot failed")


func _run() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	var view := SubViewport.new()
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	await resize_view(view, SIZES[0])
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	view.add_child(menu)
	await settle()
	for pixels in SIZES:
		await resize_view(view, pixels)
		var ui: Control = menu.get_node("MenuScale")
		check(ui.size.is_equal_approx(Vector2(view.size_2d_override)), "Menu root must fill viewport: %s" % pixels)
		for name in ["Title", "Buttons", "MenuCard", "LevelPanel", "OptionsPanel"]:
			var control: Control = ui.get_node(name)
			check(absf(control.get_rect().get_center().x - ui.size.x * 0.5) < 0.1, "Menu not centered: %s %s" % [pixels, name])
		check(ui.get_node("Buttons").size.x == 184, "Menu must not stretch buttons")
		await screenshot(view, "menu_%dx%d" % [pixels.x, pixels.y])
	menu._show_options()
	await screenshot(view, "menu_options_portrait")
	menu.queue_free()
	await settle()
	var game = load("res://scenes/main.tscn").instantiate()
	view.add_child(game)
	game.set_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_process(false)
	await settle()
	for pixels in SIZES:
		await resize_view(view, pixels)
		var ui: Control = game.get_node("Hud/HudScale")
		check(ui.size.is_equal_approx(Vector2(view.size_2d_override)), "HUD must fill viewport: %s" % pixels)
		for name in ["Wave", "WaveTimer", "UpgradePanel", "GameOver", "Victory", "BattleSummary", "PausePanel"]:
			var control: Control = ui.get_node(name)
			check(absf(control.get_rect().get_center().x - ui.size.x * 0.5) < 0.1, "HUD not centered: %s %s" % [pixels, name])
		check(absf(ui.get_node("HealthBar").get_rect().end.x - (ui.size.x - 15)) < 0.1, "HP not at right edge")
		check(ui.get_node("Wave").get_rect().end.x <= ui.get_node("Level").position.x, "Wave overlaps right HUD")
		var map: Control = ui.get_node("Minimap")
		check(map.get_rect().end.is_equal_approx(ui.size - Vector2(12, 12)), "Minimap not bottom-right")
		check(game.camera.zoom == Vector2.ONE, "Reference camera zoom changed")
		game._position_camera()
		await screenshot(view, "battle_%dx%d" % [pixels.x, pixels.y])
	# Keep the upgrade pause active while resizing; modal and icon sizes must remain fixed.
	game._open_upgrade_choice()
	for pixels in [SIZES[0], SIZES[1], SIZES[5], SIZES[6]]:
		await resize_view(view, pixels)
		var ui: Control = game.get_node("Hud/HudScale")
		var panel: Control = ui.get_node("UpgradePanel")
		check(paused and game.upgrade_open, "Resize must not unpause upgrades")
		check(panel.size == Vector2(300, 202), "Upgrade panel stretched")
		check(panel.get_rect().get_center().is_equal_approx(ui.size * 0.5), "Upgrade must remain centered while paused")
		check(panel.get_node("IconA").size == Vector2(30, 30), "Icon aspect ratio changed")
		var mech_on_screen: Vector2 = view.canvas_transform * game.mech_position
		check(mech_on_screen.distance_to(Vector2(view.size_2d_override) * 0.5) < 1.0, "Camera lost center while paused: %s" % pixels)
		await screenshot(view, "upgrade_%dx%d" % [pixels.x, pixels.y])
	var hud: Control = game.get_node("Hud/HudScale")
	# Simulate asymmetric screen cutouts even on desktop, without platform APIs.
	var safe_rect := Rect2(30, 12, 600, 340)
	hud.apply_safe_rect(safe_rect)
	await settle()
	check(hud.position.is_equal_approx(safe_rect.position), "Safe-area origin")
	check((hud.size * hud.scale).is_equal_approx(safe_rect.size), "Safe-area extent")
	check(is_equal_approx(hud.scale.x, hud.scale.y), "Safe area distorted UI")
	await screenshot(view, "safe_area")
	paused = false
	game.upgrade_open = false
	hud.get_node("UpgradePanel").hide()
	await resize_view(view, SIZES[5])
	for name in ["GameOver", "Victory", "BattleSummary", "PausePanel"]:
		hud.get_node(name).show()
		await screenshot(view, name)
		hud.get_node(name).hide()
	game.queue_free()
	await settle()
	var arena = load("res://scenes/test_arena.tscn").instantiate()
	view.add_child(arena)
	arena.set_process(false)
	await settle()
	await screenshot(view, "arena_wide")
	check(arena.level_up.size == Vector2(32, 16), "Arena buttons changed")
	check(arena.dps_bar.size == Vector2(200, 8), "Arena DPS changed")
	arena.queue_free()
	await settle()
	view.queue_free()
	print("Responsive layout: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures else 0)
