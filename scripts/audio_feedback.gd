extends Node

const MIX_RATE := 22050.0
const MAX_VOICES := 7

var player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var voices: Array[Dictionary] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = int(MIX_RATE)
	stream.buffer_length = 0.18
	player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = -15.0
	add_child(player)
	player.play()


func play_sound(kind: String) -> void:
	var voice := _make_voice(kind)
	if voice.is_empty():
		return
	voices.append(voice)
	if voices.size() > MAX_VOICES:
		voices.remove_at(0)


func _make_voice(kind: String) -> Dictionary:
	match kind:
		"cannon":
			return {"age": 0.0, "duration": 0.08, "start": 280.0, "end": 170.0, "volume": 0.17, "square": true}
		"missile":
			return {"age": 0.0, "duration": 0.22, "start": 130.0, "end": 55.0, "volume": 0.22, "square": false}
		"laser":
			return {"age": 0.0, "duration": 0.15, "start": 720.0, "end": 380.0, "volume": 0.16, "square": false}
		"xp":
			return {"age": 0.0, "duration": 0.09, "start": 560.0, "end": 790.0, "volume": 0.10, "square": false}
		"heal":
			return {"age": 0.0, "duration": 0.24, "start": 360.0, "end": 690.0, "volume": 0.16, "square": false}
		"boost":
			return {"age": 0.0, "duration": 0.20, "start": 260.0, "end": 860.0, "volume": 0.15, "square": true}
		"level":
			return {"age": 0.0, "duration": 0.38, "start": 380.0, "end": 960.0, "volume": 0.19, "square": false}
		"hurt":
			return {"age": 0.0, "duration": 0.14, "start": 135.0, "end": 65.0, "volume": 0.18, "square": true}
	return {}


func _process(_delta: float) -> void:
	if playback == null:
		playback = player.get_stream_playback()
		if playback == null:
			return
	var frames := playback.get_frames_available()
	for frame_index in range(frames):
		var sample := 0.0
		for voice_index in range(voices.size() - 1, -1, -1):
			var voice := voices[voice_index]
			var age: float = voice.age
			var duration: float = voice.duration
			if age >= duration:
				voices.remove_at(voice_index)
				continue
			var progress := age / duration
			var frequency := lerpf(float(voice.start), float(voice.end), progress)
			var wave := sin(TAU * frequency * age)
			if bool(voice.square):
				wave = signf(wave)
			var envelope := pow(1.0 - progress, 1.6) * minf(progress * 16.0, 1.0)
			sample += wave * float(voice.volume) * envelope
			voice.age = age + 1.0 / MIX_RATE
			voices[voice_index] = voice
		sample = clampf(sample, -0.7, 0.7)
		playback.push_frame(Vector2(sample, sample))
