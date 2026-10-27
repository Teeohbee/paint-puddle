extends Node2D
## The meadow: paint puddles to drive through and mix, a fountain to wash
## off in, and a rainbow to paint by filling its pots with the right colour.

const BLOB_SCENE: PackedScene = preload("res://blob/meadow_blob.tscn")
const BUSH_LAYOUT: Array[Dictionary] = [
	{"position": Vector2(250, 250), "radius": 72.0, "berries": PaintColours.RED},
	{"position": Vector2(1670, 250), "radius": 72.0, "berries": PaintColours.PURPLE},
	{"position": Vector2(1690, 640), "radius": 62.0, "berries": PaintColours.YELLOW},
	{"position": Vector2(690, 975), "radius": 48.0, "berries": PaintColours.BLUE},
	{"position": Vector2(1230, 975), "radius": 48.0, "berries": PaintColours.RED},
]
const PUDDLE_LAYOUT: Dictionary = {
	"red": Vector2(470, 830),
	"yellow": Vector2(960, 900),
	"blue": Vector2(1450, 830),
}
const FOUNTAIN_POSITION: Vector2 = Vector2(240, 600)
const RAINBOW_CENTRE: Vector2 = Vector2(960, 500)

var blob: MeadowBlob
var rainbow: RainbowBoard
var puddles: Dictionary = {}
var fountain: Fountain
var sum_card: ColourSumCard
var effects_layer: Node2D
var task_runner: TaskRunner
var is_celebrating: bool = false


func _ready() -> void:
	Music.play_track("meadow")
	add_to_group("gameplay")
	add_child(MeadowGround.new())
	rainbow = RainbowBoard.new()
	rainbow.position = RAINBOW_CENTRE
	rainbow.pot_entered.connect(on_pot_entered)
	rainbow.rainbow_finished.connect(celebrate)
	add_child(rainbow)
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

	var trail: PaintTrail = PaintTrail.new()
	add_child(trail)
	var things_on_the_grass: Node2D = Node2D.new()
	things_on_the_grass.name = "ThingsOnTheGrass"
	things_on_the_grass.y_sort_enabled = true
	add_child(things_on_the_grass)
	for bush_details in BUSH_LAYOUT:
		var bush: Bush = Bush.new()
		bush.position = bush_details.position
		bush.radius = bush_details.radius
		bush.berry_colour = bush_details.berries
		things_on_the_grass.add_child(bush)
	blob = BLOB_SCENE.instantiate()
	blob.position = Vector2(960, 740)
	things_on_the_grass.add_child(blob)
	trail.follow(blob)
	blob.bumped_into_something.connect(func(): Sound.play("bump"))
	effects_layer = Node2D.new()
	add_child(effects_layer)
	add_child(Hedge.new())
	add_child(CloudShadows.new())

	var hud: CanvasLayer = CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	sum_card = ColourSumCard.new()
	hud.add_child(sum_card)
	var task_banner: TaskBanner = TaskBanner.new()
	hud.add_child(task_banner)
	var stones_layer: Node2D = Node2D.new()
	stones_layer.name = "StonesAndDrops"
	things_on_the_grass.add_sibling(stones_layer)
	move_child(stones_layer, things_on_the_grass.get_index())
	task_runner = TaskRunner.new(stones_layer, effects_layer, task_banner)
	task_runner.blob_to_keep_clear_of = blob
	add_child(task_runner)
	var pause_menu: PauseMenu = PauseMenu.new()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)


func on_puddle_entered(puddle: PaintPuddle) -> void:
	var paint_before: String = blob.paint_name
	var paint_after: String = PaintMixing.mix(paint_before, puddle.paint_name)
	PaintSplash.burst(effects_layer, blob.position, PaintMixing.colour_of(puddle.paint_name))
	Sound.play("plop")
	task_runner.handle({"kind": "visited", "target": "puddle:" + puddle.paint_name})
	task_runner.handle({"kind": "paint_changed", "paint": paint_after})
	if paint_after == paint_before:
		blob.look.squash_stretch.kick(Vector2(-6, 6))
		return
	blob.change_paint(paint_after)
	if paint_before != "clean":
		sum_card.show_sum(paint_before, puddle.paint_name, paint_after)
		Sound.play("chime", 0.0, 1.2)


func on_fountain_entered() -> void:
	task_runner.handle({"kind": "visited", "target": "fountain"})
	if blob.paint_name == "clean":
		return
	PaintSplash.burst(effects_layer, blob.position, Color(0.85, 0.97, 1.0), 18, 600)
	Sound.play("wash", 0.0)
	blob.change_paint("clean")


func on_pot_entered(pot: PaintPot) -> void:
	if pot.is_filled or is_celebrating:
		return
	if blob.paint_name != pot.paint_name:
		pot.wobble()
		Sound.play("wobble", 0.0)
		return
	PaintSplash.burst(effects_layer, pot.global_position, PaintMixing.colour_of(pot.paint_name), 18, 600)
	var stripes_painted_before: int = 0
	for other_pot in rainbow.pots:
		if other_pot.is_filled:
			stripes_painted_before += 1
	Sound.play("pick", 0.0, 1.0 + stripes_painted_before * 0.08)
	rainbow.paint_stripe(pot.paint_name)
	task_runner.handle({"kind": "pot_filled", "paint": pot.paint_name})


func celebrate() -> void:
	is_celebrating = true
	task_runner.handle({"kind": "rainbow_finished"})
	Sound.play("chime", 0.0)
	var confetti: Confetti = Confetti.new()
	$PauseMenu.add_sibling(confetti)
	blob.look.squash_stretch.kick(Vector2(-16, 16))
	GameSettings.record_progress("rainbows_painted", GameSettings.get_progress("rainbows_painted") + 1)
	await get_tree().create_timer(5.0).timeout
	await rainbow.start_again()
	is_celebrating = false
