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

var blob: MeadowBlob
## What the blob's paint is made of. The blob only knows the paint's name,
## and printer black made from all three inks shares its name with black
## ink, so the bits are kept here for mixing and painting.
var blob_paint_bits: int = 0
var canvas: PaintCanvas
var puddles: Dictionary = {}
var fountain: Fountain
var sponge: Sponge
var effects_layer: Node2D
var last_brush_position: Vector2
var controls_hint: ControlsHint


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
		puddle.blob_entered.connect(on_puddle_entered)
		add_child(puddle)
		puddles[paint_name] = puddle
	fountain = Fountain.new()
	fountain.position = FOUNTAIN_POSITION
	fountain.blob_entered.connect(on_fountain_entered)
	add_child(fountain)
	sponge = Sponge.new()
	sponge.position = SPONGE_POSITION
	sponge.wiped.connect(wipe_picture)
	add_child(sponge)

	blob = BLOB_SCENE.instantiate()
	blob.position = Vector2(960, 480)
	add_child(blob)
	last_brush_position = blob.position + BRUSH_OFFSET
	effects_layer = Node2D.new()
	add_child(effects_layer)
	add_child(Hedge.new())
	var hud: CanvasLayer = CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	controls_hint = ControlsHint.new()
	controls_hint.shows_jump = false
	hud.add_child(controls_hint)
	var pause_menu: PauseMenu = PauseMenu.new()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)


func _physics_process(_delta: float) -> void:
	var brush_position: Vector2 = blob.position + BRUSH_OFFSET
	var has_moved: bool = brush_position != last_brush_position
	if has_moved and blob_paint_bits != 0:
		canvas.paint_line(last_brush_position, brush_position, blob_paint_bits)
	last_brush_position = brush_position


func on_puddle_entered(puddle: PaintPuddle) -> void:
	var puddle_bits: int = PaintMixing.bits_of(puddle.paint_name, colour_set)
	var bits_after: int = PaintMixing.mix_bits(blob_paint_bits, puddle_bits)
	PaintSplash.burst(effects_layer, blob.position, PaintMixing.colour_of(puddle.paint_name))
	Sound.play("plop")
	if bits_after == blob_paint_bits:
		blob.look.squash_stretch.kick(Vector2(-6, 6))
		return
	blob_paint_bits = bits_after
	var paint_before: String = blob.paint_name
	var paint_after: String = PaintMixing.paint_made_of(bits_after, colour_set)
	blob.change_paint(paint_after)
	if GameSettings.record_found("colours_found", paint_after):
		PuddleFriend.say_hello(effects_layer, blob.position, paint_after, paint_before, puddle.paint_name)


func on_fountain_entered() -> void:
	if blob_paint_bits == 0:
		return
	PaintSplash.burst(effects_layer, blob.position, Color(0.85, 0.97, 1.0), 18, 600)
	Sound.play("wash", 0.0)
	blob_paint_bits = 0
	blob.change_paint("clean")


func wipe_picture() -> void:
	canvas.wipe()
	PaintSplash.burst(effects_layer, sponge.position, Color(0.85, 0.97, 1.0), 24, 700)
	Sound.play("wash", 0.0)
	blob.look.squash_stretch.kick(Vector2(-14, 12))
