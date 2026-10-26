extends Node
## Plays the game's sound effects, all made by Synth when the game starts.
## Also owns the Music and Sfx buses and keeps their volumes in step with
## the settings.

const PLAYER_COUNT: int = 8

var sounds: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
var next_player_index: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	create_bus("Music")
	create_bus("Sfx")
	apply_volumes()
	GameSettings.setting_changed.connect(func(_setting_name, _new_value): apply_volumes())
	build_sounds()
	for player_index in PLAYER_COUNT:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = "Sfx"
		add_child(player)
		players.append(player)


func play(sound_name: String, pitch_wobble: float = 0.04) -> void:
	var player: AudioStreamPlayer = players[next_player_index]
	next_player_index = (next_player_index + 1) % players.size()
	player.stream = sounds[sound_name]
	player.pitch_scale = 1.0 + randf_range(-pitch_wobble, pitch_wobble)
	player.play()


func create_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var bus_index: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, "Master")


func apply_volumes() -> void:
	set_bus_volume("Music", GameSettings.get_setting("music_volume"))
	set_bus_volume("Sfx", GameSettings.get_setting("sound_volume"))


## Volume settings run 0 to 10; 0 is silent.
func set_bus_volume(bus_name: String, volume_setting: int) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_mute(bus_index, volume_setting == 0)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume_setting / 10.0))


func build_sounds() -> void:
	var move: PackedFloat32Array = Synth.empty_buffer(0.08)
	Synth.add_note(move, 0.0, Synth.note_frequency(84), 0.08, "marimba", 0.35)
	sounds["move"] = Synth.to_stream(move)

	var pick: PackedFloat32Array = Synth.empty_buffer(0.6)
	Synth.add_note(pick, 0.0, Synth.note_frequency(84), 0.5, "bell", 0.35)
	Synth.add_note(pick, 0.09, Synth.note_frequency(91), 0.5, "bell", 0.35)
	sounds["pick"] = Synth.to_stream(pick)

	var locked: PackedFloat32Array = Synth.empty_buffer(0.35)
	Synth.add_slide(locked, 0.0, 330, 260, 0.16, 0.4)
	Synth.add_slide(locked, 0.16, 300, 220, 0.18, 0.4)
	sounds["locked"] = Synth.to_stream(locked)

	var splat: PackedFloat32Array = Synth.empty_buffer(0.3)
	Synth.add_squelch(splat, 0.0, 0.28, 0.3)
	Synth.add_slide(splat, 0.0, 220, 90, 0.2, 0.35)
	sounds["splat"] = Synth.to_stream(splat)

	var pop: PackedFloat32Array = Synth.empty_buffer(0.12)
	Synth.add_slide(pop, 0.0, 1100, 500, 0.11, 0.45)
	sounds["pop"] = Synth.to_stream(pop)

	var plop: PackedFloat32Array = Synth.empty_buffer(0.16)
	Synth.add_slide(plop, 0.0, 260, 720, 0.15, 0.5)
	sounds["plop"] = Synth.to_stream(plop)

	var bump: PackedFloat32Array = Synth.empty_buffer(0.15)
	Synth.add_slide(bump, 0.0, 150, 60, 0.14, 0.6)
	sounds["bump"] = Synth.to_stream(bump)

	var jump: PackedFloat32Array = Synth.empty_buffer(0.18)
	Synth.add_slide(jump, 0.0, 380, 820, 0.17, 0.35)
	sounds["jump"] = Synth.to_stream(jump)

	var chime: PackedFloat32Array = Synth.empty_buffer(1.2)
	var chime_notes: Array[int] = [72, 76, 79, 84, 88]
	for note_index in chime_notes.size():
		Synth.add_note(chime, note_index * 0.08, Synth.note_frequency(chime_notes[note_index]), 0.8, "bell", 0.25)
	sounds["chime"] = Synth.to_stream(chime)

	var wobble: PackedFloat32Array = Synth.empty_buffer(0.3)
	Synth.add_slide(wobble, 0.0, 420, 380, 0.12, 0.3)
	Synth.add_slide(wobble, 0.12, 400, 350, 0.15, 0.3)
	sounds["wobble"] = Synth.to_stream(wobble)
