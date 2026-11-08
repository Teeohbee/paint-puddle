class_name PaintStudio
extends Node2D
## Paint mode: no tasks, just a big sheet of paper. The blob paints wherever
## it goes in whatever colour it's wearing. Puddles mix colours like the
## meadow, white and black make them lighter and darker, the fountain washes
## the blob clean, and the sponge wipes the picture.

const BLOB_SCENE: PackedScene = preload("res://blob/meadow_blob.tscn")
const FIRST_PUDDLE_POSITION: Vector2 = Vector2(480, 930)
const PUDDLE_SPACING: float = 260.0
const FOUNTAIN_POSITION: Vector2 = Vector2(200, 920)
const SPONGE_POSITION: Vector2 = Vector2(1780, 900)
## Paint comes off the bottom of the blob, not its middle.
const BRUSH_OFFSET: Vector2 = Vector2(0, 24)
const PAPER_COLOUR: Color = Color(1.0, 0.98, 0.94)

## Paint colours or printer colours, picked on the way in.
static var colour_set: String = "paint"

## Player one's blob. Everyone painting is in `players`.
var blob: MeadowBlob
var players: Array[PaintPlayer] = []
var canvas: PaintCanvas
var puddles: Dictionary = {}
var fountain: Fountain
var sponge: Sponge
var effects_layer: Node2D
var controls_hint: ControlsHint
## Which pads the two players are on, from PlayerSession. -1 for player one
## means any pad or the keyboard (one player), and for player two nobody.
var player_one_device: int = -1
var player_two_device: int = -1
## Off in Splat party, where only splats paint.
var paints_trails: bool = true


func _ready() -> void:
	Music.play_track("meadow")
	add_to_group("gameplay")
	var paper: ColorRect = ColorRect.new()
	paper.color = PAPER_COLOUR
	paper.size = Vector2(PaintCanvas.PICTURE_SIZE)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(paper)
	canvas = PaintCanvas.new()
	canvas.colour_set = colour_set
	add_child(canvas)
	var puddle_names: Array = PaintMixing.puddles_for(colour_set)
	for puddle_index in puddle_names.size():
		var paint_name: String = puddle_names[puddle_index]
		var puddle: PaintPuddle = PaintPuddle.new()
		puddle.paint_name = paint_name
		puddle.position = FIRST_PUDDLE_POSITION + Vector2(PUDDLE_SPACING * puddle_index, 0)
		puddle.body_entered.connect(on_body_entered_puddle.bind(puddle))
		add_child(puddle)
		puddles[paint_name] = puddle
	fountain = Fountain.new()
	fountain.position = FOUNTAIN_POSITION
	fountain.body_entered.connect(on_body_entered_fountain)
	add_child(fountain)
	sponge = Sponge.new()
	sponge.position = SPONGE_POSITION
	sponge.wiped.connect(wipe_picture)
	add_child(sponge)

	blob = BLOB_SCENE.instantiate()
	blob.position = Vector2(960, 480)
	add_child(blob)
	players.append(PaintPlayer.new(blob, 0, blob.position + BRUSH_OFFSET))
	effects_layer = Node2D.new()
	add_child(effects_layer)
	add_child(Hedge.new())
	var hud: CanvasLayer = CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	controls_hint = ControlsHint.new()
	configure_controls_hint()
	hud.add_child(controls_hint)
	var pause_menu: PauseMenu = PauseMenu.new()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)
	Input.joy_connection_changed.connect(on_joy_connection_changed)
	if PlayerSession.is_two_player():
		player_one_device = PlayerSession.device_of(0)
		add_player_two(PlayerSession.device_of(1))


## Paint shows the four arrows; places with an A button show that too.
func configure_controls_hint() -> void:
	controls_hint.shows_jump = false


func add_player_two(device: int) -> void:
	player_two_device = device
	# Each blob now listens to its own pad; player one keeps the keyboard
	blob.move_actions = PlayerControls.make_pad_actions("player_one", player_one_device, true)
	var player_two_blob: MeadowBlob = BLOB_SCENE.instantiate()
	player_two_blob.move_actions = PlayerControls.make_pad_actions("player_two", device, false)
	player_two_blob.position = (blob.position + Vector2(140, 0)).clamp(Vector2(60, 60), Vector2(1860, 1020))
	add_child(player_two_blob)
	move_child(player_two_blob, blob.get_index() + 1)
	player_two_blob.look.wears_bow = true
	# No bumps - the blobs just drift through each other
	blob.add_collision_exception_with(player_two_blob)
	player_two_blob.add_collision_exception_with(blob)
	players.append(PaintPlayer.new(player_two_blob, 1, player_two_blob.position + BRUSH_OFFSET))
	PaintSplash.burst(effects_layer, player_two_blob.position, Color.WHITE)
	Sound.play("pop")
	player_two_blob.look.squash_stretch.kick(Vector2(-14, 12))


func on_joy_connection_changed(device: int, connected: bool) -> void:
	if not connected and players.size() == 2 and device == player_two_device:
		remove_player_two()


func remove_player_two() -> void:
	var leaving_player: PaintPlayer = players.pop_back()
	PaintSplash.burst(effects_layer, leaving_player.blob.position, Color.WHITE)
	Sound.play("pop")
	leaving_player.blob.queue_free()
	player_two_device = -1


func _physics_process(_delta: float) -> void:
	for player in players:
		var brush_position: Vector2 = player.blob.position + BRUSH_OFFSET
		var has_moved: bool = brush_position != player.last_brush_position
		if paints_trails and has_moved and player.paint_bits != 0:
			canvas.paint_line(player.last_brush_position, brush_position, player.paint_bits, player.brush_number)
		player.last_brush_position = brush_position


func player_of(entered_blob: Node2D) -> PaintPlayer:
	for player in players:
		if player.blob == entered_blob:
			return player
	return null


func on_body_entered_puddle(body: Node2D, puddle: PaintPuddle) -> void:
	var player: PaintPlayer = player_of(body)
	if player != null:
		on_puddle_entered(puddle, player)


func on_body_entered_fountain(body: Node2D) -> void:
	var player: PaintPlayer = player_of(body)
	if player != null:
		on_fountain_entered(player)


func on_puddle_entered(puddle: PaintPuddle, player: PaintPlayer) -> void:
	var player_blob: MeadowBlob = player.blob
	var puddle_bits: int = PaintMixing.bits_of(puddle.paint_name, colour_set)
	var bits_after: int = PaintMixing.mix_bits(player.paint_bits, puddle_bits)
	PaintSplash.burst(effects_layer, player_blob.position, PaintMixing.colour_of(puddle.paint_name))
	Sound.play("plop")
	if bits_after == player.paint_bits:
		player_blob.look.squash_stretch.kick(Vector2(-6, 6))
		return
	player.paint_bits = bits_after
	var paint_before: String = player_blob.paint_name
	var paint_after: String = PaintMixing.paint_made_of(bits_after, colour_set)
	player_blob.change_paint(paint_after)
	if GameSettings.record_found("colours_found", paint_after):
		PuddleFriend.say_hello(effects_layer, player_blob.position, paint_after, paint_before, puddle.paint_name)


func on_fountain_entered(player: PaintPlayer) -> void:
	if player.paint_bits == 0:
		return
	PaintSplash.burst(effects_layer, player.blob.position, Color(0.85, 0.97, 1.0), 18, 600)
	Sound.play("wash", 0.0)
	player.paint_bits = 0
	player.blob.change_paint("clean")


func wipe_picture() -> void:
	canvas.wipe()
	PaintSplash.burst(effects_layer, sponge.position, Color(0.85, 0.97, 1.0), 24, 700)
	Sound.play("wash", 0.0)
	for player in players:
		player.blob.look.squash_stretch.kick(Vector2(-14, 12))
