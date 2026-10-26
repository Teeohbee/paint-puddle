class_name Synth
extends RefCounted
## A tiny synthesiser. Builds sounds and music as lists of samples, then turns
## them into AudioStreamWAVs. Every sound in the game is made here.

const MIX_RATE: int = 22050


static func empty_buffer(seconds: float) -> PackedFloat32Array:
	var buffer: PackedFloat32Array = PackedFloat32Array()
	buffer.resize(int(seconds * MIX_RATE))
	return buffer


static func to_stream(buffer: PackedFloat32Array, loops: bool = false) -> AudioStreamWAV:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(buffer.size() * 2)
	for sample_index in buffer.size():
		var sample: float = clampf(buffer[sample_index], -1.0, 1.0)
		bytes.encode_s16(sample_index * 2, int(sample * 32767.0))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	if loops:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = buffer.size()
	return stream


static func note_frequency(midi_note: int) -> float:
	return 440.0 * pow(2.0, (midi_note - 69) / 12.0)


## Adds one note to the buffer. Voices: "bell", "marimba", "bass", "pad", "blip".
static func add_note(buffer: PackedFloat32Array, start_seconds: float, frequency: float,
		duration_seconds: float, voice: String, volume: float) -> void:
	var first_sample: int = int(start_seconds * MIX_RATE)
	var sample_count: int = int(duration_seconds * MIX_RATE)
	for offset in sample_count:
		var sample_index: int = first_sample + offset
		if sample_index >= buffer.size():
			return
		var time: float = float(offset) / MIX_RATE
		buffer[sample_index] += voice_sample(voice, frequency, time, duration_seconds) * volume


static func voice_sample(voice: String, frequency: float, time: float, duration_seconds: float) -> float:
	var phase: float = TAU * frequency * time
	var attack: float = minf(time / 0.006, 1.0)
	var release: float = clampf((duration_seconds - time) / 0.03, 0.0, 1.0)
	match voice:
		"bell":
			return attack * release * (sin(phase) * exp(-time * 5.0) + 0.3 * sin(phase * 2.0) * exp(-time * 9.0) \
				+ 0.12 * sin(phase * 3.01) * exp(-time * 14.0))
		"marimba":
			return attack * release * (sin(phase) * exp(-time * 9.0) + 0.2 * sin(phase * 4.0) * exp(-time * 25.0))
		"bass":
			var triangle: float = 2.0 * absf(2.0 * fposmod(frequency * time, 1.0) - 1.0) - 1.0
			return attack * release * triangle * exp(-time * 2.5)
		"pad":
			var swell: float = minf(time / 0.4, 1.0) * clampf((duration_seconds - time) / 0.5, 0.0, 1.0)
			return swell * (sin(phase) + sin(phase * 1.004) + 0.5 * sin(phase * 2.002)) / 2.5
		"blip":
			return attack * release * sin(phase)
	return 0.0


## A note whose pitch slides from one frequency to another.
static func add_slide(buffer: PackedFloat32Array, start_seconds: float, from_frequency: float,
		to_frequency: float, duration_seconds: float, volume: float) -> void:
	var first_sample: int = int(start_seconds * MIX_RATE)
	var sample_count: int = int(duration_seconds * MIX_RATE)
	var phase: float = 0.0
	for offset in sample_count:
		var sample_index: int = first_sample + offset
		if sample_index >= buffer.size():
			return
		var how_far: float = float(offset) / sample_count
		var frequency: float = lerpf(from_frequency, to_frequency, how_far)
		phase += TAU * frequency / MIX_RATE
		var envelope: float = minf(offset / 60.0, 1.0) * (1.0 - how_far) * (1.0 - how_far)
		buffer[sample_index] += sin(phase) * envelope * volume


## Soft filtered noise, like a squelch of paint.
static func add_squelch(buffer: PackedFloat32Array, start_seconds: float, duration_seconds: float, volume: float) -> void:
	var first_sample: int = int(start_seconds * MIX_RATE)
	var sample_count: int = int(duration_seconds * MIX_RATE)
	var smoothed: float = 0.0
	for offset in sample_count:
		var sample_index: int = first_sample + offset
		if sample_index >= buffer.size():
			return
		var how_far: float = float(offset) / sample_count
		var smoothing: float = lerpf(0.35, 0.04, how_far)
		smoothed = lerpf(smoothed, randf_range(-1.0, 1.0), smoothing)
		buffer[sample_index] += smoothed * (1.0 - how_far) * volume * 2.5
