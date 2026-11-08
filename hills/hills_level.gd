class_name HillsLevel
extends Node2D
## One Rainbow Hills run: walk and hop to the rainbow flag, popping letter
## balloons on the way. Falling into a gap is fine - a cloud brings you back.

const HILLS_MENU: String = "res://ui/hills_menu.tscn"
const FALL_LINE_BELOW_GROUND: float = 260.0
const BALLOON_HEIGHT_ABOVE_GROUND: float = 85.0
## High enough to need a jump, low enough that any jump reaches it.
const PAINT_POT_HEIGHT_ABOVE_GROUND: float = 190.0
## How far along the level the first and last paint pots stand.
const POT_FIRST_FRACTION: float = 0.3
const POT_LAST_FRACTION: float = 0.66
## Far enough in that the blob isn't squeezed against the left of the screen,
## with room to get going before the first jump: every level starts with 700
## of flat ground.
const BLOB_START_X: float = 300.0
## How far apart two players can get. Past this the one behind is carried up
## to the one in front, so both always stay on screen.
const MAX_SEPARATION: float = 1100.0
## Where the carried blob lands, behind its friend.
const CATCH_UP_DISTANCE_BEHIND: float = 200.0

## Which level to play next; set by the hills menu before it opens this scene.
static var level_to_play: int = 0
## The level just finished, so the menu can wait on the one after it. -1 when
## the menu is opened some other way.
static var level_just_finished: int = -1

var level: Dictionary
var ground: HillsGround
## Player one's blob. Everyone playing is in `players`.
var blob: HillsBlob
var players: Array[HillsPlayer] = []
## Player one's paint, for checks that only look at one blob.
var blob_paint: String:
	get:
		return players[0].paint
var word_bar: WordBar
var controls_hint: ControlsHint
var effects_layer: Node2D
var camera: Camera2D
## Pots already taken, so two blobs touching one in the same moment only mix once.
var taken_pots: Array[HillsPaintPot] = []
var lowest_ground: float = 0.0
var is_finished: bool = false
## Which pads the two players are on, from PlayerSession. -1 for player one
## means any pad or the keyboard (one player), and for player two nobody.
var player_one_device: int = -1
var player_two_device: int = -1


func _ready() -> void:
	add_to_group("gameplay")
	Music.play_track("hills")
	level = HillsLevels.LEVELS[level_to_play]
	var scene: Dictionary = HillsScenes.scene_for(level)
	var backdrop: HillsBackdrop = HillsBackdrop.new()
	backdrop.scene = scene
	add_child(backdrop)
	var cloud_sea: Node2D = Node2D.new()
	cloud_sea.z_index = -1
	add_child(cloud_sea)
	ground = HillsGround.new()
	ground.scene = scene
	add_child(ground)
	ground.build(level.pieces, GameSettings.get_setting("gap_size_percent") / 100.0)
	for top in ground.ground_tops:
		for point in top:
			lowest_ground = maxf(lowest_ground, point.y)
	cloud_sea.draw.connect(func(): HillsBackdrop.draw_cloud_sea(cloud_sea, -400, ground.level_length + 400, lowest_ground + 150, scene.cloud_sea))
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
	blob.position = Vector2(BLOB_START_X, ground.height_at(BLOB_START_X) - HillsBlob.BODY_RADIUS - 2)
	add_child(blob)
	players.append(HillsPlayer.new(blob, level.paint))
	blob.look.paint_colour = PaintMixing.colour_of(level.paint)
	place_paint_pots()
	splash_when_landing(blob)
	add_camera()
	var pause_menu: PauseMenu = PauseMenu.new()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)
	PlayerSession.devices_changed.connect(on_devices_changed)
	if PlayerSession.is_two_player():
		add_player_two()


## Each blob listens to its own pad; player one keeps the keyboard. Safe to
## call again when a pad comes back under a new id: the blobs keep the same
## action names, so they simply start hearing the new pad.
func bind_pads() -> void:
	player_one_device = PlayerSession.device_of(0)
	player_two_device = PlayerSession.device_of(1)
	var first_blob: HillsBlob = players[0].blob
	var second_blob: HillsBlob = players[1].blob
	first_blob.move_actions = PlayerControls.make_pad_actions("player_one", player_one_device, true)
	first_blob.act_action = PlayerControls.make_pad_act_action("player_one", player_one_device, true)
	second_blob.move_actions = PlayerControls.make_pad_actions("player_two", player_two_device, false)
	second_blob.act_action = PlayerControls.make_pad_act_action("player_two", player_two_device, false)


func on_devices_changed() -> void:
	if players.size() == 2:
		bind_pads()


func add_player_two() -> void:
	var player_two_blob: HillsBlob = HillsBlob.new()
	var start_x: float = blob.position.x + 100.0
	var ground_height: float = ground.height_at(start_x)
	if ground_height == INF:
		player_two_blob.position = blob.position
	else:
		player_two_blob.position = Vector2(start_x, ground_height - HillsBlob.BODY_RADIUS - 2)
	add_child(player_two_blob)
	player_two_blob.look.wears_bow = true
	player_two_blob.look.paint_colour = PaintMixing.colour_of(level.paint)
	# No bumps - the blobs just drift through each other
	blob.add_collision_exception_with(player_two_blob)
	player_two_blob.add_collision_exception_with(blob)
	players.append(HillsPlayer.new(player_two_blob, level.paint))
	bind_pads()
	splash_when_landing(player_two_blob)
	PaintSplash.burst(effects_layer, player_two_blob.position, Color.WHITE)
	Sound.play("pop")
	player_two_blob.look.squash_stretch.kick(Vector2(-14, 12))


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


## Pots of paint spread along the second third of the way, up where it takes
## a jump. The last, two-thirds along, is the level's own; the ones before it
## are other colours, so two players can have a pot each.
func place_paint_pots() -> void:
	var paints: Array[String] = HillsLevels.pot_paints(level_to_play)
	for pot_index in paints.size():
		var how_far: float = lerpf(POT_FIRST_FRACTION, POT_LAST_FRACTION, pot_index / float(maxi(paints.size() - 1, 1)))
		if paints.size() == 1:
			how_far = POT_LAST_FRACTION
		var x: float = nearest_ground_x(ground.level_length * how_far)
		var pot: HillsPaintPot = HillsPaintPot.new()
		pot.paint_name = paints[pot_index]
		pot.position = Vector2(x, ground.height_at(x) - PAINT_POT_HEIGHT_ABOVE_GROUND)
		# The level listens for the blob itself, so it knows whose paint to mix
		pot.body_entered.connect(func(body): on_pot_touched(pot, body))
		effects_layer.add_child(pot)


func splash_when_landing(landing_blob: HillsBlob) -> void:
	landing_blob.landed.connect(func(): PaintSplash.burst(effects_layer, landing_blob.position + Vector2(0, 40), Color(1, 1, 1, 0.8), 8, 220))


func player_of(touching_blob: Node2D) -> HillsPlayer:
	for player in players:
		if player.blob == touching_blob:
			return player
	return null


func on_pot_touched(pot: HillsPaintPot, touching_blob: Node2D) -> void:
	var player: HillsPlayer = player_of(touching_blob)
	if player == null or taken_pots.has(pot):
		return
	taken_pots.append(pot)
	mix_into_player(player, pot.paint_name)


func mix_into_player(player: HillsPlayer, added_paint: String) -> void:
	player.paint = PaintMixing.mix(player.paint, added_paint)
	if player.colour_tween != null:
		player.colour_tween.kill()
	player.colour_tween = create_tween()
	player.colour_tween.tween_property(player.blob.look, "paint_colour", PaintMixing.colour_of(player.paint), 0.3)
	FloatingText.show_at(effects_layer, player.blob.position - Vector2(0, 160), PaintMixing.word_for(player.paint) + "!",
		PaintMixing.colour_of(player.paint), 90, 1.8, 50.0)


## Moves x out of a gap, and away from a step, onto plain ground.
func nearest_ground_x(x: float) -> float:
	for distance in range(0, 600, 20):
		for candidate in [x + distance, x - distance]:
			var here: float = ground.height_at(candidate)
			if here != INF and absf(ground.height_at(candidate - 70) - here) < 4 and absf(ground.height_at(candidate + 70) - here) < 4:
				return candidate
	return x


## The camera belongs to the level, not a blob, so it can follow everyone.
func add_camera() -> void:
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.drag_vertical_enabled = true
	camera.drag_top_margin = 0.35
	camera.drag_bottom_margin = 0.2
	camera.offset = Vector2(220, -60)
	camera.limit_left = -60
	camera.limit_right = int(ground.level_length + 60)
	camera.limit_bottom = int(lowest_ground + 360)
	camera.position = focus_position()
	add_child(camera)
	camera.make_current()


## The middle of everyone playing.
func focus_position() -> Vector2:
	var total: Vector2 = Vector2.ZERO
	for player in players:
		total += player.blob.position
	return total / players.size()


func _physics_process(_delta: float) -> void:
	camera.position = focus_position()
	carry_the_one_left_behind()
	for player in players:
		var falling_blob: HillsBlob = player.blob
		if not falling_blob.is_being_carried and falling_blob.position.y > lowest_ground + FALL_LINE_BELOW_GROUND:
			var ground_point: Vector2 = ground.safe_ground_point_near(falling_blob.last_ground_position.x)
			var safe_spot: Vector2 = ground_point - Vector2(0, HillsBlob.BODY_RADIUS + 30.0)
			RescueCloud.rescue(falling_blob, effects_layer, safe_spot)


## If two players have drifted too far apart, a cloud brings the one at the
## back up to the one in front.
func carry_the_one_left_behind() -> void:
	if players.size() < 2:
		return
	var leader: HillsBlob = players[0].blob
	var straggler: HillsBlob = players[1].blob
	if straggler.position.x > leader.position.x:
		leader = players[1].blob
		straggler = players[0].blob
	var is_too_far: bool = leader.position.x - straggler.position.x > MAX_SEPARATION
	if not is_too_far or leader.is_being_carried or straggler.is_being_carried:
		return
	var catch_up_x: float = maxf(leader.last_ground_position.x - CATCH_UP_DISTANCE_BEHIND, 0.0)
	var ground_point: Vector2 = ground.safe_ground_point_near(catch_up_x)
	RescueCloud.rescue(straggler, effects_layer, ground_point - Vector2(0, HillsBlob.BODY_RADIUS + 30.0))


func finish() -> void:
	if is_finished:
		return
	is_finished = true
	for player in players:
		player.blob.can_move = false
	Sound.play("chime", 0.0)
	FloatingText.show_at(effects_layer, blob.position - Vector2(0, 220), "Well done!", PaintColours.PURPLE, 130, 2.6, 60.0)
	var confetti_layer: CanvasLayer = CanvasLayer.new()
	confetti_layer.layer = 11
	add_child(confetti_layer)
	confetti_layer.add_child(Confetti.new())
	var completed: int = GameSettings.get_progress("hills_levels_completed")
	GameSettings.record_progress("hills_levels_completed", maxi(completed, level_to_play + 1))
	level_just_finished = level_to_play
	for hop in 3:
		for player in players:
			player.blob.velocity.y = -700
			player.blob.look.squash_stretch.kick(Vector2(12, -10))
		await get_tree().create_timer(0.7, false).timeout
	await get_tree().create_timer(1.2, false).timeout
	SceneManager.go_to(HILLS_MENU)
