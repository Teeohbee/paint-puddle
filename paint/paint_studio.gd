class_name PaintStudio
extends Node2D
## Paint mode: no tasks, just a big sheet of paper. The blob paints wherever
## it goes in whatever colour it's wearing. Puddles mix colours like the
## meadow, the fountain washes the blob clean, and the sponge wipes the picture.

const BLOB_SCENE: PackedScene = preload("res://blob/meadow_blob.tscn")
const PUDDLE_LAYOUT: Dictionary = {
	"red": Vector2(560, 930),
	"yellow": Vector2(960, 930),
	"blue": Vector2(1360, 930),
}
const FOUNTAIN_POSITION: Vector2 = Vector2(200, 920)
const SPONGE_POSITION: Vector2 = Vector2(1700, 900)
## Paint comes off the bottom of the blob, not its middle.
const BRUSH_OFFSET: Vector2 = Vector2(0, 24)
const PAPER_COLOUR: Color = Color(1.0, 0.98, 0.94)

var blob: MeadowBlob
var canvas: PaintCanvas
var puddles: Dictionary = {}
var fountain: Fountain
var sponge: Sponge
var effects_layer: Node2D
var last_brush_position: Vector2


func _ready() -> void:
	Music.play_track("meadow")
	add_to_group("gameplay")
	var paper: ColorRect = ColorRect.new()
	paper.color = PAPER_COLOUR
	paper.size = Vector2(PaintCanvas.PICTURE_SIZE)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(paper)
	canvas = PaintCanvas.new()
	add_child(canvas)
	for paint_name in PUDDLE_LAYOUT:
		var puddle: PaintPuddle = PaintPuddle.new()
		puddle.paint_name = paint_name
		puddle.position = PUDDLE_LAYOUT[paint_name]
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
	blob.bumped_into_something.connect(func(): Sound.play("bump"))
	last_brush_position = blob.position + BRUSH_OFFSET
	effects_layer = Node2D.new()
	add_child(effects_layer)
	add_child(Hedge.new())
	var pause_menu: PauseMenu = PauseMenu.new()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)


func _physics_process(_delta: float) -> void:
	var brush_position: Vector2 = blob.position + BRUSH_OFFSET
	var has_moved: bool = brush_position != last_brush_position
	if has_moved and blob.paint_name != "clean":
		canvas.paint_line(last_brush_position, brush_position, PaintMixing.colour_of(blob.paint_name))
	last_brush_position = brush_position


func on_puddle_entered(puddle: PaintPuddle) -> void:
	var paint_after: String = PaintMixing.mix(blob.paint_name, puddle.paint_name)
	PaintSplash.burst(effects_layer, blob.position, PaintMixing.colour_of(puddle.paint_name))
	Sound.play("plop")
	if paint_after == blob.paint_name:
		blob.look.squash_stretch.kick(Vector2(-6, 6))
		return
	blob.change_paint(paint_after)


func on_fountain_entered() -> void:
	if blob.paint_name == "clean":
		return
	PaintSplash.burst(effects_layer, blob.position, Color(0.85, 0.97, 1.0), 18, 600)
	Sound.play("wash", 0.0)
	blob.change_paint("clean")


func wipe_picture() -> void:
	canvas.wipe()
	PaintSplash.burst(effects_layer, sponge.position, Color(0.85, 0.97, 1.0), 24, 700)
	Sound.play("wash", 0.0)
	blob.look.squash_stretch.kick(Vector2(-14, 12))
