extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _peak(capture: AudioEffectCapture) -> float:
	var frames := capture.get_buffer(capture.get_frames_available())
	var peak := 0.0
	for frame in frames:
		peak = maxf(peak, maxf(absf(frame.x), absf(frame.y)))
	return peak


func _run() -> void:
	var bus_index := AudioServer.bus_count
	AudioServer.add_bus()
	AudioServer.set_bus_name(bus_index, "MenuMusicCapture")
	var capture := AudioEffectCapture.new()
	capture.buffer_length = 2.0
	AudioServer.add_bus_effect(bus_index, capture)
	var menu := load("res://scenes/main_menu.tscn").instantiate() as Control
	root.add_child(menu)
	var player := menu.get_node("MenuMusic") as AudioStreamPlayer
	var track := player.stream as AudioStreamWAV
	player.bus = "MenuMusicCapture"
	player.play()
	_check(player.playing, "Main menu must start its music")
	_check(track.loop_end > track.loop_begin, "Main menu music loop has an empty range")
	_check(is_equal_approx(player.volume_db, menu.MENU_MUSIC_VOLUME_DB), "Main menu music has an unexpected volume")
	await create_timer(0.8).timeout
	var peak := _peak(capture)
	print("Menu music: %.2f seconds, peak %.6f" % [track.get_length(), peak])
	_check(peak > 0.001, "Main menu music outputs silence")
	player.seek(track.get_length() - 0.15)
	capture.clear_buffer()
	await create_timer(0.5).timeout
	_check(player.playing, "Main menu music stopped at the end")
	_check(player.get_playback_position() < 1.0, "Main menu music did not loop")
	_check(_peak(capture) > 0.001, "Looped main menu music outputs silence")
	menu.queue_free()
	await process_frame
	AudioServer.remove_bus(bus_index)
	print("PASS: menu music emits sound and loops" if failures == 0 else "FAIL: %d menu music checks" % failures)
	quit(0 if failures == 0 else 1)
