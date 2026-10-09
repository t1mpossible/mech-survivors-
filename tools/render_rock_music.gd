extends SceneTree

# Second original music sketch: modern driving game-rock with a small FM-synth accent.
# Offline render only. This does not alter the game's playback or sound balance.

const OUTPUT := "res://assets/audio/rock_desert_demo_v2.wav"
const RATE := 44100
const BPM := 148.0
const STEP_TIME := 60.0 / BPM / 4.0
const STEP_FRAMES := STEP_TIME * RATE
const BARS := 16
const FRAMES := int(round(BARS * 16 * STEP_FRAMES))

var l := PackedFloat32Array()
var r := PackedFloat32Array()
var random_state := 20261008


func _initialize() -> void:
	call_deferred("_render")


func _render() -> void:
	l.resize(FRAMES)
	r.resize(FRAMES)
	var roots := [52, 48, 55, 50, 52, 48, 55, 50, 52, 48, 55, 50, 48, 50, 52, 52]
	var hooks := [
		[76, 79, 83], [76, 79, 83], [79, 83, 86], [78, 81, 86],
		[76, 79, 83], [79, 76, 72], [79, 83, 86], [81, 78, 74],
		[83, 86, 88], [83, 79, 76], [86, 83, 79], [81, 78, 86],
		[76, 79, 83], [78, 81, 86], [83, 79, 76], [76, 83, 88]
	]
	for bar in range(BARS):
		var start := bar * 16
		var chord: int = roots[bar]
		var riff := [0, 2, 3, 6, 8, 10, 11, 14] if bar % 4 != 3 else [0, 2, 3, 6, 8, 10, 12, 13, 14, 15]
		for step in riff:
			# Tight double-tracked palm-muted power chords, panned slightly apart.
			_guitar(start + step, chord, 1.15 if step not in [0, 8] else 2.1, 0.18, -0.48, 0.997)
			_guitar(start + step, chord + 7, 1.15 if step not in [0, 8] else 2.1, 0.095, -0.48, 0.997)
			_guitar(start + step, chord, 1.15 if step not in [0, 8] else 2.1, 0.18, 0.48, 1.003)
			_guitar(start + step, chord + 7, 1.15 if step not in [0, 8] else 2.1, 0.095, 0.48, 1.003)
		for step in [0, 3, 6, 8, 11, 14]:
			_bass(start + step, chord - 12, 1.9 if step in [0, 8] else 1.3, 0.32)
		if bar >= 4:
			_lead(start, hooks[bar][0], 3.4, 0.13)
			_lead(start + 7, hooks[bar][1], 2.8, 0.12)
			_lead(start + 12, hooks[bar][2], 3.2, 0.13)
		if bar >= 8:
			for step in [1, 5, 9, 13]:
				_fm_accent(start + step, chord + 24 + (7 if step in [5, 13] else 0), 0.65, 0.035)
		for step in [0, 6, 8, 11]:
			_drum(start + step, "kick", 0.48)
		for step in [4, 12]:
			_drum(start + step, "snare", 0.30)
		for step in range(0, 16, 2):
			_drum(start + step, "hat", 0.095 if step % 4 == 0 else 0.060)
		if bar in [0, 4, 8, 12]:
			_drum(start, "crash", 0.065)
		if bar in [3, 7, 11, 15]:
			for step in [13, 14, 15]:
				_drum(start + step, "snare", 0.10)
	# Fade the last 100 ms into the first sample so the preview can repeat cleanly.
	var tail_frames := int(0.10 * RATE)
	var first_l := l[0]
	var first_r := r[0]
	for index in range(tail_frames):
		var ratio := float(index + 1) / float(tail_frames)
		var at := FRAMES - tail_frames + index
		l[at] = lerpf(l[at], first_l, ratio)
		r[at] = lerpf(r[at], first_r, ratio)
	_write_wav()
	quit()


func _guitar(step: int, midi_note: int, length_steps: float, gain: float, pan: float, detune: float) -> void:
	var at := int(round(step * STEP_FRAMES))
	var length := mini(int((length_steps * STEP_TIME + 0.035) * RATE), FRAMES - at)
	var hz := _pitch(midi_note) * detune
	for index in range(length):
		var t := float(index) / RATE
		var p := TAU * hz * t
		# Rich harmonic stack with waveshaping approximates an electric-guitar riff.
		var harmonics := 0.0
		for partial in range(1, 7):
			harmonics += sin(p * partial) / float(partial)
		var pinch := minf(t * 230.0, 1.0)
		var decay := exp(-t * (9.0 if length_steps < 2.0 else 5.0))
		var tail := minf((float(length - index) / RATE) / 0.035, 1.0)
		var sound := tanh(harmonics * 2.4) * pinch * decay * tail * gain
		_mix(at + index, sound, pan)


func _bass(step: int, midi_note: int, length_steps: float, gain: float) -> void:
	var at := int(round(step * STEP_FRAMES))
	var length := mini(int((length_steps * STEP_TIME + 0.04) * RATE), FRAMES - at)
	var hz := _pitch(midi_note)
	for index in range(length):
		var t := float(index) / RATE
		var p := TAU * hz * t
		var envelope := minf(t * 190.0, 1.0) * exp(-t * 4.8) * minf(float(length - index) / (RATE * 0.04), 1.0)
		var sound := tanh((sin(p) * 0.9 + sin(p * 2.0) * 0.35 + sin(p * 3.0) * 0.15) * 1.8) * envelope * gain
		_mix(at + index, sound, 0.0)


func _lead(step: int, midi_note: int, length_steps: float, gain: float) -> void:
	var at := int(round(step * STEP_FRAMES))
	var length := mini(int((length_steps * STEP_TIME + 0.11) * RATE), FRAMES - at)
	var hz := _pitch(midi_note)
	for index in range(length):
		var t := float(index) / RATE
		var vibrato := 1.0 + sin(t * TAU * 5.2) * minf(t * 2.0, 1.0) * 0.004
		var p := TAU * hz * t * vibrato
		var envelope := minf(t * 80.0, 1.0) * minf(float(length - index) / (RATE * 0.11), 1.0)
		var harmonics := sin(p) * 0.67 + sin(p * 2.0) * 0.3 + sin(p * 3.0) * 0.18
		var sound := tanh(harmonics * 1.7) * envelope * gain
		_mix(at + index, sound, 0.04)
		var echo_at := at + index + int(0.19 * RATE)
		if echo_at < FRAMES:
			_mix(echo_at, sound * 0.15, -0.20)


func _fm_accent(step: int, midi_note: int, length_steps: float, gain: float) -> void:
	var at := int(round(step * STEP_FRAMES))
	var length := mini(int(length_steps * STEP_FRAMES), FRAMES - at)
	var hz := _pitch(midi_note)
	for index in range(length):
		var t := float(index) / RATE
		var p := TAU * hz * t
		var sound := sin(p + sin(p * 2.0) * exp(-t * 12.0) * 2.0) * exp(-t * 15.0) * gain
		_mix(at + index, sound, 0.1)


func _drum(step: int, kind: String, gain: float) -> void:
	var at := int(round(step * STEP_FRAMES))
	var duration := 0.33 if kind == "kick" else 0.22 if kind == "snare" else 0.48 if kind == "crash" else 0.09
	var length := mini(int(duration * RATE), FRAMES - at)
	var previous := 0.0
	for index in range(length):
		var t := float(index) / RATE
		random_state = (random_state * 1664525 + 1013904223) & 0x7fffffff
		var noise := float(random_state) / 1073741824.0 - 1.0
		var sound := 0.0
		match kind:
			"kick":
				var p := TAU * (48.0 * t + 6.2 * (1.0 - exp(-t * 31.0)))
				sound = (sin(p) + noise * exp(-t * 110.0) * 0.15) * exp(-t * 15.0)
			"snare":
				sound = (noise * 0.78 + sin(TAU * 195.0 * t) * 0.25) * exp(-t * 17.0)
			"hat":
				sound = (noise - previous) * exp(-t * 48.0) * 0.67
			"crash":
				sound = (noise - previous) * exp(-t * 9.0) * 0.54
		previous = noise
		_mix(at + index, sound * gain, 0.0)


func _pitch(note: int) -> float:
	return 440.0 * pow(2.0, float(note - 69) / 12.0)


func _mix(frame: int, sound: float, pan: float) -> void:
	l[frame] += sound * (1.0 - pan)
	r[frame] += sound * (1.0 + pan)


func _write_wav() -> void:
	var data := PackedByteArray()
	data.resize(FRAMES * 4)
	var peak := 0.0
	var power := 0.0
	for index in range(FRAMES):
		var a := tanh(l[index] * 0.83) * 0.82
		var b := tanh(r[index] * 0.83) * 0.82
		peak = maxf(peak, maxf(absf(a), absf(b)))
		power += (a * a + b * b) * 0.5
		data.encode_s16(index * 4, roundi(clampf(a, -1.0, 1.0) * 32767.0))
		data.encode_s16(index * 4 + 2, roundi(clampf(b, -1.0, 1.0) * 32767.0))
	var header := PackedByteArray()
	header.resize(44)
	_tag(header, 0, "RIFF")
	header.encode_u32(4, 36 + data.size())
	_tag(header, 8, "WAVE")
	_tag(header, 12, "fmt ")
	header.encode_u32(16, 16)
	header.encode_u16(20, 1)
	header.encode_u16(22, 2)
	header.encode_u32(24, RATE)
	header.encode_u32(28, RATE * 4)
	header.encode_u16(32, 4)
	header.encode_u16(34, 16)
	_tag(header, 36, "data")
	header.encode_u32(40, data.size())
	var file := FileAccess.open(OUTPUT, FileAccess.WRITE)
	assert(file != null, "Cannot write the preview WAV")
	file.store_buffer(header)
	file.store_buffer(data)
	file.close()
	print("Rendered %s: %.2f sec, peak %.3f, RMS %.3f" % [OUTPUT, float(FRAMES) / RATE, peak, sqrt(power / FRAMES)])


func _tag(bytes: PackedByteArray, offset: int, tag: String) -> void:
	var raw := tag.to_ascii_buffer()
	for index in range(raw.size()):
		bytes[offset + index] = raw[index]
