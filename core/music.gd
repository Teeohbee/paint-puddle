extends Node
## Gentle music, composed and played by the game itself. Each track is eight
## bars on a pentatonic scale, so no note can sound wrong, built on a
## background thread when the game starts. Tracks crossfade when the scene
## changes, and duck under the pause menu.

const CROSSFADE_SECONDS: float = 1.2
const SILENT_DB: float = -40.0
const DUCKED_DB: float = -11.0
const PENTATONIC_STEPS: Array[int] = [0, 2, 4, 7, 9]

## Each track: tempo, melody voice, how busy the melody is, and a seed so it
## comes out the same every time.
const TRACKS: Dictionary = {
	"title": {"beats_per_minute": 84, "melody_voice": "bell", "melody_busyness": 0.45, "seed": 11, "ticks": false},
	"meadow": {"beats_per_minute": 96, "melody_voice": "marimba", "melody_busyness": 0.6, "seed": 23, "ticks": true},
	"hills": {"beats_per_minute": 112, "melody_voice": "marimba", "melody_busyness": 0.7, "seed": 37, "ticks": true},
}

## C, A minor, F, G - each chord as MIDI notes for the pad, root first.
const CHORDS: Array = [[48, 52, 55], [45, 48, 52], [41, 45, 48], [43, 47, 50]]

var finished_tracks: Dictionary = {}
var track_tasks: Dictionary = {}
## Written by the composing threads, read on the main thread once each task is done.
var composed_streams: Dictionary = {}
var composed_streams_lock: Mutex = Mutex.new()
var wanted_track: String = ""
var playing_track: String = ""
var players: Array[AudioStreamPlayer] = []
var active_player_index: int = 0
var duck_effect: AudioEffectAmplify


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for player_index in 2:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = "Music"
		player.volume_db = SILENT_DB
		add_child(player)
		players.append(player)
	duck_effect = AudioEffectAmplify.new()
	AudioServer.add_bus_effect(AudioServer.get_bus_index("Music"), duck_effect)
	for track_name in TRACKS:
		track_tasks[track_name] = WorkerThreadPool.add_task(compose_track.bind(track_name))


## Asks for a track. If it's still being composed it starts as soon as it's ready.
func play_track(track_name: String) -> void:
	wanted_track = track_name
	start_wanted_track_if_ready()


func stop() -> void:
	wanted_track = ""
	if playing_track != "":
		fade_out(players[active_player_index])
		playing_track = ""


func _process(_delta: float) -> void:
	collect_finished_tracks()
	if wanted_track != playing_track:
		start_wanted_track_if_ready()


func collect_finished_tracks() -> void:
	for track_name in track_tasks.keys():
		if not WorkerThreadPool.is_task_completed(track_tasks[track_name]):
			continue
		WorkerThreadPool.wait_for_task_completion(track_tasks[track_name])
		track_tasks.erase(track_name)
		composed_streams_lock.lock()
		finished_tracks[track_name] = composed_streams[track_name]
		composed_streams_lock.unlock()


## Quitting while tracks are still being composed waits for them, so no
## thread is left running as the game shuts down.
func _exit_tree() -> void:
	for track_name in track_tasks:
		WorkerThreadPool.wait_for_task_completion(track_tasks[track_name])


func start_wanted_track_if_ready() -> void:
	if wanted_track == "" or wanted_track == playing_track:
		return
	collect_finished_tracks()
	if not finished_tracks.has(wanted_track):
		return
	fade_out(players[active_player_index])
	active_player_index = 1 - active_player_index
	var incoming: AudioStreamPlayer = players[active_player_index]
	incoming.stream = finished_tracks[wanted_track]
	incoming.volume_db = SILENT_DB
	incoming.play()
	var fade_in: Tween = create_tween()
	fade_in.set_ignore_time_scale(true)
	fade_in.tween_property(incoming, "volume_db", 0.0, CROSSFADE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	playing_track = wanted_track


func fade_out(player: AudioStreamPlayer) -> void:
	if not player.playing:
		return
	var fade: Tween = create_tween()
	fade.set_ignore_time_scale(true)
	fade.tween_property(player, "volume_db", SILENT_DB, CROSSFADE_SECONDS)
	fade.tween_callback(player.stop)


func duck(should_duck: bool) -> void:
	var tween: Tween = create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_property(duck_effect, "volume_db", DUCKED_DB if should_duck else 0.0, 0.3)


func compose_track(track_name: String) -> void:
	var stream: AudioStreamWAV = compose(TRACKS[track_name])
	composed_streams_lock.lock()
	composed_streams[track_name] = stream
	composed_streams_lock.unlock()


## Eight bars: bars 5-8 repeat the rhythm of bars 1-4 with new notes, so it
## has a shape without sounding random.
static func compose(track: Dictionary) -> AudioStreamWAV:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = track.seed
	var seconds_per_beat: float = 60.0 / track.beats_per_minute
	var bar_count: int = 8
	var loop_seconds: float = bar_count * 4 * seconds_per_beat
	var tail_seconds: float = 2.5
	var buffer: PackedFloat32Array = Synth.empty_buffer(loop_seconds + tail_seconds)

	var rhythm: Array[bool] = []
	for slot_index in 4 * 8:
		var is_strong_slot: bool = slot_index % 4 == 0
		rhythm.append(is_strong_slot or random.randf() < track.melody_busyness)

	var scale_position: int = 7
	for bar_index in bar_count:
		var chord: Array = CHORDS[bar_index % CHORDS.size()]
		var bar_start: float = bar_index * 4 * seconds_per_beat
		for chord_note in chord:
			Synth.add_note(buffer, bar_start, Synth.note_frequency(chord_note + 12), 4 * seconds_per_beat, "pad", 0.05)
		Synth.add_note(buffer, bar_start, Synth.note_frequency(chord[0] - 12), 2 * seconds_per_beat, "bass", 0.22)
		Synth.add_note(buffer, bar_start + 2 * seconds_per_beat, Synth.note_frequency(chord[0] - 5), 2 * seconds_per_beat, "bass", 0.18)
		if track.ticks:
			for beat_index in 4:
				Synth.add_squelch(buffer, bar_start + (beat_index + 0.5) * seconds_per_beat, 0.04, 0.04)
		for slot_in_bar in 8:
			var slot_index: int = (bar_index % 4) * 8 + slot_in_bar
			if not rhythm[slot_index]:
				continue
			scale_position = clampi(scale_position + random.randi_range(-2, 2), 3, 12)
			if slot_in_bar == 0:
				scale_position = nearest_chord_tone(scale_position, chord)
			var midi_note: int = 60 + 12 * (scale_position / 5) + PENTATONIC_STEPS[scale_position % 5]
			var note_start: float = bar_start + slot_in_bar * seconds_per_beat / 2.0
			Synth.add_note(buffer, note_start, Synth.note_frequency(midi_note), seconds_per_beat * 1.5, track.melody_voice, 0.2)

	return Synth.to_stream(wrap_tail_into_loop(buffer, int(loop_seconds * Synth.MIX_RATE)), true)


## Moves a scale position to the nearest note that's in the chord, if one is close.
static func nearest_chord_tone(scale_position: int, chord: Array) -> int:
	for distance in [0, 1, -1, 2, -2]:
		var candidate: int = scale_position + distance
		var pitch_class: int = PENTATONIC_STEPS[posmod(candidate, 5)]
		for chord_note in chord:
			if posmod(chord_note, 12) == pitch_class:
				return candidate
	return scale_position


## Notes still ringing at the end of the loop are folded back onto the start,
## so the loop joins up without a click, then the whole thing is evened out.
static func wrap_tail_into_loop(buffer: PackedFloat32Array, loop_sample_count: int) -> PackedFloat32Array:
	var looped: PackedFloat32Array = buffer.slice(0, loop_sample_count)
	for tail_index in buffer.size() - loop_sample_count:
		looped[tail_index] += buffer[loop_sample_count + tail_index]
	var loudest: float = 0.001
	for sample in looped:
		loudest = maxf(loudest, absf(sample))
	var make_up: float = 0.55 / loudest
	for sample_index in looped.size():
		looped[sample_index] *= make_up
	return looped
