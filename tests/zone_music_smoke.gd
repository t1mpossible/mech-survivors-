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
	root.get_node("GameState").selected_planet = 1
	var bus_index := AudioServer.bus_count
	AudioServer.add_bus()
	AudioServer.set_bus_name(bus_index, "MusicSmokeCapture")
	var capture := AudioEffectCapture.new()
	capture.buffer_length = 2.0
	AudioServer.add_bus_effect(bus_index, capture)
	var game := load("res://scenes/main.tscn").instantiate() as Node2D
	root.add_child(game)
	game.set_process(false)
	var player := game.get_node("ZoneMusic") as AudioStreamPlayer
	var track := player.stream as AudioStreamWAV
	_check(player.playing, "Zone 1 must start music")
	_check(track.loop_end > track.loop_begin, "Music loop has an empty range")
	print("Music loop: begin=%d end=%d duration=%.2f" % [track.loop_begin, track.loop_end, track.get_length()])
	# Isolate music from generated weapon sounds: playing=true alone can hide silence.
	player.bus = "MusicSmokeCapture"
	player.play()
	await create_timer(1.0).timeout
	var peak := _peak(capture)
	print("Music output: peak=%.6f position=%.3f" % [peak, player.get_playback_position()])
	_check(peak > 0.001, "Music bus outputs silence")
	_check(player.get_playback_position() > 0.25, "Music playback position does not advance")
	game._open_upgrade_choice()
	_check(is_equal_approx(player.volume_db, game.ZONE_MUSIC_UPGRADE_VOLUME_DB), "Upgrade screen must lower music by half")
	_check(player.process_mode == Node.PROCESS_MODE_ALWAYS, "Music must keep processing while the game is paused")
	var position_before_upgrade_pause := player.get_playback_position()
	await create_timer(0.3, true).timeout
	_check(player.get_playback_position() > position_before_upgrade_pause, "Music stopped during upgrade pause")
	game._choose_upgrade(0)
	_check(is_equal_approx(player.volume_db, game.ZONE_MUSIC_VOLUME_DB), "Music volume must recover after choosing an upgrade")
	player.seek(track.get_length() - 0.15)
	capture.clear_buffer()
	await create_timer(0.6).timeout
	_check(player.playing, "Music stopped at end of track")
	_check(player.get_playback_position() < 1.0, "Music did not loop back to the beginning")
	_check(_peak(capture) > 0.001, "Looped music outputs silence")
	game.queue_free()
	await process_frame
	AudioServer.remove_bus(bus_index)
	print("PASS: nonzero music signal, advancing playback and full-track loop" if failures == 0 else "FAIL: %d music checks" % failures)
	quit(0 if failures == 0 else 1)
