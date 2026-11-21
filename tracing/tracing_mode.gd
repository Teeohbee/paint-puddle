class_name TracingMode
extends Node2D
## Tracing: one big dotted lowercase letter on the meadow grass, started and
## drawn the way school teaches it. Drive along the dots to paint them, in
## order. Each finished letter opens the next, in school's order.

const BLOB_SCENE: PackedScene = preload("res://blob/meadow_blob.tscn")
## How close the blob has to come to a dot to paint it (playtested).
const REACH: float = 60.0
const SECONDS_TO_CHEER: float = 3.5
## The paint for each letter in turn. Not green: it hides on the grass.
const LETTER_PAINTS: Array[String] = ["red", "orange", "blue", "purple", "yellow"]
const WRITE_MENU: String = "res://ui/write_menu.tscn"
## The blob starts in whichever corner is furthest from the start dot, off the letter.
const STARTING_SPOTS: Array[Vector2] = [Vector2(220, 300), Vector2(1700, 300), Vector2(220, 900), Vector2(1700, 900)]

## The letter to trace, as its place in TracingLetters.ORDER.
static var letter_to_play: int = 0
## The letter just finished, so a menu can start on the one after (-1 for none).
static var letter_just_finished: int = -1


## Each letter opens once the one before it is traced, or all of them with
## "Open everything" in the grown-up settings.
static func is_letter_open(index: int) -> bool:
	return index <= GameSettings.get_progress("letters_traced") or GameSettings.get_setting("open_all_clock_rungs") == 1

var letter_index: int = 0
var letter: String = ""
var progress: TraceProgress
var drawing: TraceDrawing
var blob: MeadowBlob
var rhyme_card: RhymeCard
var effects_layer: Node2D
var is_cheering: bool = false


func _ready() -> void:
	Music.play_track("meadow")
	add_to_group("gameplay")
	# A parent draws before its children, so the grass goes behind everything
	var ground: MeadowGround = MeadowGround.new()
	ground.z_index = -1
	add_child(ground)
	drawing = TraceDrawing.new()
	drawing.name = "Trace"
	add_child(drawing)
	blob = BLOB_SCENE.instantiate()
	add_child(blob)
	add_child(Hedge.new())
	effects_layer = Node2D.new()
	effects_layer.name = "Effects"
	add_child(effects_layer)
	var hud: CanvasLayer = CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	var controls_hint: ControlsHint = ControlsHint.new()
	controls_hint.shows_jump = false
	hud.add_child(controls_hint)
	rhyme_card = RhymeCard.new()
	hud.add_child(rhyme_card)
	var pause_menu: PauseMenu = PauseMenu.new()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)
	start_letter(clampi(letter_to_play, 0, TracingLetters.ORDER.length() - 1))
	blob.position = furthest_spot_from(progress.next_dot())


func start_letter(index: int) -> void:
	letter_index = index
	letter = TracingLetters.ORDER[index]
	progress = TraceProgress.new(TracingLetters.strokes_for(letter))
	var paint_name: String = LETTER_PAINTS[index % LETTER_PAINTS.size()]
	drawing.progress = progress
	drawing.paint_colour = PaintMixing.colour_of(paint_name)
	blob.change_paint(paint_name)
	rhyme_card.show_letter(letter, TracingLetters.rhyme_for(letter), drawing.paint_colour)
	is_cheering = false


func furthest_spot_from(point: Vector2) -> Vector2:
	var furthest: Vector2 = STARTING_SPOTS[0]
	for spot in STARTING_SPOTS:
		if spot.distance_to(point) > furthest.distance_to(point):
			furthest = spot
	return furthest


func _physics_process(_delta: float) -> void:
	if is_cheering or progress.is_finished():
		return
	var painted: int = progress.paint_near(blob.position, REACH)
	if painted == 0:
		return
	var total_dots: int = 0
	for stroke in progress.strokes:
		total_dots += stroke.size()
	Sound.play("pick", 0.0, 0.9 + 0.5 * progress.painted_count() / total_dots)
	if progress.is_finished():
		finish_letter()


## A cheer, the letter saved if it's the one being climbed, then the next.
func finish_letter() -> void:
	is_cheering = true
	letter_just_finished = letter_index
	if letter_index == GameSettings.get_progress("letters_traced"):
		GameSettings.record_progress("letters_traced", letter_index + 1)
	rhyme_card.celebrate()
	Sound.play("chime", 0.0)
	effects_layer.add_child(Confetti.new())
	FloatingText.show_at(effects_layer, Vector2(960, 540), "Well done!", PaintColours.PURPLE, 130, 2.0, 60.0)
	blob.look.squash_stretch.kick(Vector2(-16, 16))
	await get_tree().create_timer(SECONDS_TO_CHEER, false).timeout
	if not is_inside_tree():
		return
	if letter_index + 1 >= TracingLetters.ORDER.length():
		SceneManager.go_to(WRITE_MENU)
		return
	start_letter(letter_index + 1)
