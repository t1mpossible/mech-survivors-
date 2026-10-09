extends SceneTree

# Original 8-bar battle-music sketch. Run with:
# Godot --headless --path . --script res://tools/render_retro_music.gd
# The WAV is an audition asset, not yet loaded by the game.

const SAMPLE_RATE := 22050
const BPM := 130.0
const STEPS_PER_BAR := 16
const BAR_COUNT := 8
const STEP_SECONDS := 60.0 / BPM / 4.0
const STEP_SAMPLES := SAMPLE_RATE * STEP_SECONDS
const TOTAL_SAMPLES := int(round(STEP_SAMPLES * STEPS_PER_BAR * BAR_COUNT))
const OUTPUT_PATH := "res://assets/audio/retro_desert_demo_v1.wav"

var left := PackedFloat32Array()
var right := PackedFloat32Array()
var noise_state := 76121


func _initialize() -> void:
	call_deferred("_render")


func _render() -> void:
	left.resize(TOTAL_SAMPLES)
	right.resize(TOTAL_SAMPLES)
	var roots := [45, 41, 43, 40, 45, 41, 38, 40] # A, F, G, E, A, F, D, E
	var hooks := [
		[76, 79, 81, 84, 81, 79, 76, 74],
		[77, 81, 84, 81, 79, 77, 76, 72],
		[79, 83, 86, 83, 81, 79, 76, 74],
		[76, 80, 83, 80, 76, 74, 71, 74],
		[76, 79, 81, 84, 86, 84, 81, 79],
		[77, 81, 84, 88, 84, 81, 79, 77],
		[74, 77, 81, 84, 81, 77, 74, 72],
		[76, 80, 83, 88, 83, 80, 76, 83],
	]
	var lead_steps := [0, 3, 4, 7, 8, 10, 13, 14]
	var lead_lengths := [3, 1, 3, 1, 2, 3, 1, 2]
	var bass_steps := [0, 3, 4, 7, 8, 10, 12, 14]
	for bar in range(BAR_COUNT):
		var base := bar * STEPS_PER_BAR
		var root_note: int = roots[bar]
		for index in range(bass_steps.size()):
			var note := root_note + (12 if index == 5 else 0)
			_note(base + bass_steps[index], 1.9, note, "bass", 0.27, -0.05)
		for index in range(lead_steps.size()):
			_note(base + lead_steps[index], float(lead_lengths[index]) * 0.9, hooks[bar][index], "lead", 0.22, 0.04)
		for step in range(0, STEPS_PER_BAR, 2):
			var chord := [root_note + 24, root_note + 27, root_note + 31]
			var arp_note: int = chord[(step / 2 + bar) % chord.size()]
			_note(base + step, 1.2, arp_note, "arp", 0.065, -0.12)
		for step in [0, 8]:
			_note(base + step, 3.0, root_note + 12, "brass", 0.08, 0.12)
			_note(base + step, 3.0, root_note + (16 if bar in [3, 7] else 15), "brass", 0.055, 0.12)
		for step in range(0, STEPS_PER_BAR, 4):
			_drum(base + step, "kick", 0.38)
		for step in [4, 12]:
			_drum(base + step, "snare", 0.20)
		for step in range(0, STEPS_PER_BAR, 2):
			_drum(base + step, "hat", 0.065 if step % 4 == 0 else 0.045)
		if bar in [3, 7]:
			for step in [13, 14, 15]:
				_drum(base + step, "snare", 0.07)
	# Smooth the last 90 ms into the opening sample to avoid a click at the loop seam.
	var wrap_samples := int(0.09 * SAMPLE_RATE)
	var opening_left := left[0]
	var opening_right := right[0]
	for index in range(wrap_samples):
		var blend := float(index + 1) / float(wrap_samples)
		var tail := TOTAL_SAMPLES - wrap_samples + index
		left[tail] = lerpf(left[tail], opening_left, blend)
		right[tail] = lerpf(right[tail], opening_right, blend)
	var pcm := PackedByteArray()
	pcm.resize(TOTAL_SAMPLES * 4)
	var peak := 0.0
	var sum_squares := 0.0
	for index in range(TOTAL_SAMPLES):
		var sample_left := tanh(left[index] * 0.86) * 0.73
		var sample_right := tanh(right[index] * 0.86) * 0.73
		peak = maxf(peak, maxf(absf(sample_left), absf(sample_right)))
		sum_squares += (sample_left * sample_left + sample_right * sample_right) * 0.5
		pcm.encode_s16(index * 4, roundi(clampf(sample_left, -1.0, 1.0) * 32767.0))
		pcm.encode_s16(index * 4 + 2, roundi(clampf(sample_right, -1.0, 1.0) * 32767.0))
	var header := PackedByteArray()
	header.resize(44)
	_tag(header, 0, "RIFF")
	header.encode_u32(4, 36 + pcm.size())
	_tag(header, 8, "WAVE")
	_tag(header, 12, "fmt ")
	header.encode_u32(16, 16)
	header.encode_u16(20, 1) # PCM
	header.encode_u16(22, 2) # stereo
	header.encode_u32(24, SAMPLE_RATE)
	header.encode_u32(28, SAMPLE_RATE * 4)
	header.encode_u16(32, 4)
	header.encode_u16(34, 16)
	_tag(header, 36, "data")
	header.encode_u32(40, pcm.size())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	assert(file != null, "Cannot write %s" % OUTPUT_PATH)
	file.store_buffer(header)
	file.store_buffer(pcm)
	file.close()
	print("Rendered %s: %.2f s, peak %.3f, RMS %.3f" % [OUTPUT_PATH, float(TOTAL_SAMPLES) / SAMPLE_RATE, peak, sqrt(sum_squares / TOTAL_SAMPLES)])
	quit()


func _tag(bytes: PackedByteArray, offset: int, tag: String) -> void:
	var data := tag.to_ascii_buffer()
	for index in range(data.size()):
		bytes[offset + index] = data[index]


func _note(step: int, length_steps: float, midi_note: int, voice: String, gain: float, pan: float) -> void:
	var start := int(round(step * STEP_SAMPLES))
	var length_seconds := length_steps * STEP_SECONDS
	var release := 0.085 if voice == "lead" else 0.055 if voice == "bass" else 0.04
	var length := mini(int((length_seconds + release) * SAMPLE_RATE), TOTAL_SAMPLES - start)
	var hz := 440.0 * pow(2.0, (midi_note - 69) / 12.0)
	for index in range(length):
		var time := float(index) / SAMPLE_RATE
		var phase := TAU * hz * time
		var envelope := minf(time / 0.007, 1.0) * minf((length_seconds + release - time) / release, 1.0)
		envelope = maxf(envelope, 0.0)
		var wave := 0.0
		match voice:
			"lead":
				# FM-like bright bell/brass hybrid, fading to a stable singing tone.
				var fm := 2.8 * exp(-time * 4.0)
				wave = sin(phase + fm * sin(phase * 2.0)) * 0.72 + sin(phase * 2.0) * 0.2
			"bass":
				wave = sin(phase + 0.9 * sin(phase * 2.0)) * 0.75 + sin(phase * 2.0) * 0.2
			"arp":
				wave = sin(phase) * 0.65 + sin(phase * 3.0) * 0.2
			"brass":
				wave = sin(phase + 1.5 * exp(-time * 7.0) * sin(phase * 2.0)) * 0.7
		var sample := wave * envelope * gain
		left[start + index] += sample * (1.0 - pan)
		right[start + index] += sample * (1.0 + pan)


func _drum(step: int, drum: String, gain: float) -> void:
	var start := int(round(step * STEP_SAMPLES))
	var duration := 0.24 if drum == "kick" else 0.15 if drum == "snare" else 0.07
	var length := mini(int(duration * SAMPLE_RATE), TOTAL_SAMPLES - start)
	var previous_noise := 0.0
	for index in range(length):
		var time := float(index) / SAMPLE_RATE
		noise_state = (noise_state * 1664525 + 1013904223) & 0x7fffffff
		var noise := float(noise_state) / 1073741824.0 - 1.0
		var sample := 0.0
		match drum:
			"kick":
				var phase := TAU * (53.0 * time + 4.4 * (1.0 - exp(-time * 23.0)))
				sample = sin(phase) * exp(-time * 19.0) + noise * exp(-time * 110.0) * 0.12
			"snare":
				sample = (noise * 0.75 + sin(TAU * 185.0 * time) * 0.25) * exp(-time * 22.0)
			"hat":
				sample = (noise - previous_noise) * 0.6 * exp(-time * 58.0)
		previous_noise = noise
		left[start + index] += sample * gain
		right[start + index] += sample * gain
