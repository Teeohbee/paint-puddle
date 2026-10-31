class_name HillsLevel
extends Node2D
## One Rainbow Hills run: walk and hop to the rainbow flag, popping letter
## balloons on the way. Falling into a gap is fine - a cloud brings you back.

const HILLS_MENU: String = "res://ui/hills_menu.tscn"
const FALL_LINE_BELOW_GROUND: float = 260.0
const BALLOON_HEIGHT_ABOVE_GROUND: float = 85.0

## Which level to play next; set by the hills menu before it opens this scene.
static var level_to_play: int = 0

var level: Dictionary
var ground: HillsGround
var blob: HillsBlob
var word_bar: WordBar
var controls_hint: ControlsHint
var effects_layer: Node2D
var lowest_ground: float = 0.0
var is_finished: bool = false


func _ready() -> void:
	add_to_group("gameplay")
	Music.play_track("hills")
	level = HillsLevels.LEVELS[level_to_play]
	add_child(HillsBackdrop.new())
	var cloud_sea: Node2D = Node2D.new()
	cloud_sea.z_index = -1
	add_child(cloud_sea)
	ground = HillsGround.new()
	add_child(ground)
	ground.build(level.pieces, GameSettings.get_setting("gap_size_percent") / 100.0)
	for top in ground.ground_tops:
		for point in top:
			lowest_ground = maxf(lowest_ground, point.y)
	cloud_sea.draw.connect(func(): HillsBackdrop.draw_cloud_sea(cloud_sea, -400, ground.level_length + 400, lowest_ground + 150))
	add_level_edges()

	effects_layer = Node2D.new()
	add_child(effects_layer)
	var hud: CanvasLayer = CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	word_bar = WordBar.new()
	hud.add_child(word_bar)
	word_bar.set_word(level.word)
	controls_hint = ControlsHint.new()
	hud.add_child(controls_hint)
	place_balloons()

	var flag: RainbowFlag = RainbowFlag.new()
	flag.position = Vector2(ground.level_length - 160, ground.height_at(ground.level_length - 160))
	flag.reached.connect(finish)
	add_child(flag)

	blob = HillsBlob.new()
	blob.position = Vector2(160, ground.height_at(160) - HillsBlob.BODY_RADIUS - 2)
	add_child(blob)
	blob.look.paint_colour = PaintMixing.colour_of(level.paint)
	blob.landed.connect(func(): PaintSplash.burst(effects_layer, blob.position + Vector2(0, 40), Color(1, 1, 1, 0.8), 8, 220))
	add_camera()
	var pause_menu: PauseMenu = PauseMenu.new()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)


## Walls at both ends so the blob can't walk out of the level.
func add_level_edges() -> void:
	for wall_x in [-30.0, ground.level_length + 30.0]:
		var wall: StaticBody2D = StaticBody2D.new()
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = Vector2(60, 3000)
		var collision: CollisionShape2D = CollisionShape2D.new()
		collision.shape = shape
		wall.add_child(collision)
		wall.position = Vector2(wall_x, 0)
		add_child(wall)


## Letters spread evenly along the way, at a height the blob walks through.
func place_balloons() -> void:
	var word: String = level.word
	var usable_start: float = 500.0
	var usable_end: float = ground.level_length - 400.0
	for letter_index in word.length():
		var x: float = lerpf(usable_start, usable_end, (letter_index + 0.5) / word.length())
		x = nearest_ground_x(x)
		var balloon: LetterBalloon = LetterBalloon.new()
		balloon.letter = word[letter_index]
		balloon.letter_index = letter_index
		balloon.paint_colour = PaintColours.RAINBOW[letter_index % PaintColours.RAINBOW.size()]
		balloon.position = Vector2(x, ground.height_at(x) - BALLOON_HEIGHT_ABOVE_GROUND)
		balloon.popped.connect(func(popped_balloon): word_bar.pop_letter(popped_balloon.letter_index))
		effects_layer.add_child(balloon)


## Moves x out of a gap, and away from a step, onto plain ground.
func nearest_ground_x(x: float) -> float:
	for distance in range(0, 600, 20):
		for candidate in [x + distance, x - distance]:
			var here: float = ground.height_at(candidate)
			if here != INF and absf(ground.height_at(candidate - 70) - here) < 4 and absf(ground.height_at(candidate + 70) - here) < 4:
				return candidate
	return x


func add_camera() -> void:
	var camera: Camera2D = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.drag_vertical_enabled = true
	camera.drag_top_margin = 0.35
	camera.drag_bottom_margin = 0.2
	camera.offset = Vector2(220, -60)
	camera.limit_left = -60
	camera.limit_right = int(ground.level_length + 60)
	camera.limit_bottom = int(lowest_ground + 360)
	blob.add_child(camera)
	camera.make_current()


func _physics_process(_delta: float) -> void:
	if not blob.is_being_carried and blob.position.y > lowest_ground + FALL_LINE_BELOW_GROUND:
		var ground_point: Vector2 = ground.safe_ground_point_near(blob.last_ground_position.x)
		var safe_spot: Vector2 = ground_point - Vector2(0, HillsBlob.BODY_RADIUS + 30.0)
		RescueCloud.rescue(blob, effects_layer, safe_spot)


func finish() -> void:
	if is_finished:
		return
	is_finished = true
	blob.can_move = false
	Sound.play("chime", 0.0)
	FloatingText.show_at(effects_layer, blob.position - Vector2(0, 220), "Well done!", PaintColours.PURPLE, 130, 2.6, 60.0)
	var confetti_layer: CanvasLayer = CanvasLayer.new()
	confetti_layer.layer = 11
	add_child(confetti_layer)
	confetti_layer.add_child(Confetti.new())
	var completed: int = GameSettings.get_progress("hills_levels_completed")
	GameSettings.record_progress("hills_levels_completed", maxi(completed, level_to_play + 1))
	for hop in 3:
		blob.velocity.y = -700
		blob.look.squash_stretch.kick(Vector2(12, -10))
		await get_tree().create_timer(0.7, false).timeout
	await get_tree().create_timer(1.2, false).timeout
	SceneManager.go_to(HILLS_MENU)
