extends SceneTree

# Run with a rendering driver (not --headless). Captures the actual menu layout.
func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png("res://.godot/menu_preview.png")
	assert(result == OK, "Failed to save menu preview")
	print("Menu preview captured.")
	quit()
