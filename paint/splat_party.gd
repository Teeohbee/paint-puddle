class_name SplatParty
extends PaintStudio
## Splat party: Paint's paper, puddles, fountain and sponge, but moving
## doesn't paint. A flings a splat of the blob's paint instead.

var paint_colour_set_before: String = ""


func _init() -> void:
	paints_trails = false


func _exit_tree() -> void:
	PaintStudio.colour_set = paint_colour_set_before


func _ready() -> void:
	# Paint colours only; put the Paint menu's choice back on the way out.
	# This waits for _ready, not _init: a restart builds the new scene before
	# the old one leaves the tree, and its _exit_tree would undo this.
	paint_colour_set_before = PaintStudio.colour_set
	PaintStudio.colour_set = "paint"
	super()
	for pal_index in PAL_COUNT:
		var pal: SplatPal = SplatPal.new()
		add_child(pal)
		# Under the effects, hedge and HUD, like the blobs
		move_child(pal, effects_layer.get_index())
		pals.append(pal)
	for thing_index in THING_COUNT:
		add_thing(unused_thing_name(), Vector2(randf_range(250, 1670), randf_range(250, 720)))


## A drawing not already out on the paper, so there are never two the same.
func unused_thing_name() -> String:
	var names_out: Array[String] = []
	for thing in things:
		names_out.append(thing.thing_name)
	var choices: Array[String] = []
	for thing_name in ThingDrawings.NAMES:
		if not names_out.has(thing_name):
			choices.append(thing_name)
	return choices.pick_random()


func add_thing(thing_name: String, spot: Vector2) -> SplatThing:
	var thing: SplatThing = SplatThing.new()
	thing.thing_name = thing_name
	thing.position = spot
	add_child(thing)
	move_child(thing, effects_layer.get_index())
	things.append(thing)
	return thing


## The one who's been here longest waves goodbye and a newcomer pops in.
## The leaver stops being a target straight away.
func swap_oldest_thing() -> void:
	if things.is_empty():
		return
	var leaver: SplatThing = things.pop_front()
	leaver.wave_goodbye()
	var newcomer: SplatThing = add_thing(unused_thing_name(), Vector2(randf_range(250, 1670), randf_range(250, 720)))
	newcomer.pop_in()


func configure_controls_hint() -> void:
	controls_hint.shows_jump = false
	controls_hint.shows_act_button = true


const PAL_COUNT: int = 3
## Word characters from the Meadow, picked at random each visit.
const THING_COUNT: int = 3
const THING_SWAP_SECONDS: float = 45.0
const THROW_DISTANCE: float = 420.0
## Aim help for small thumbs: a target this close to straight ahead gets the splat.
const AIM_CONE_RADIANS: float = 22.0 * PI / 180.0
const AIM_RANGE: float = 600.0
## A ball this close to someone, once it's well on its way, hits them.
const HIT_RADIUS: float = 50.0
const HIT_AFTER_PROGRESS: float = 0.3
const THROW_COOLDOWN_SECONDS: float = 0.35
## Splats land on the paper above the puddle row, so they fall short of it.
const LANDING_AREA: Rect2 = Rect2(40, 40, 1840, 790)

var balls: Array[SplatBall] = []
var pals: Array[SplatPal] = []
var things: Array[SplatThing] = []
var seconds_until_thing_swap: float = THING_SWAP_SECONDS


func add_player_two(device: int) -> void:
	super(device)
	# Each pad's A throws for its own blob, like the sticks move their own
	players[0].act_action = PlayerControls.make_pad_act_action("player_one", player_one_device, true)
	players[1].act_action = PlayerControls.make_pad_act_action("player_two", device, false)


func _physics_process(delta: float) -> void:
	super(delta)
	seconds_until_thing_swap -= delta
	if seconds_until_thing_swap <= 0.0:
		seconds_until_thing_swap = THING_SWAP_SECONDS
		swap_oldest_thing()
	for player in players:
		player.seconds_until_next_throw = maxf(0.0, player.seconds_until_next_throw - delta)
		if Input.is_action_just_pressed(player.act_action):
			throw_splat(player)
	for ball in balls.duplicate():
		ball.advance(delta)
		var struck: Node2D = null
		if ball.progress() > HIT_AFTER_PROGRESS:
			struck = target_near(ball)
		if struck != null or ball.has_landed():
			land_ball(ball, struck)


## Flings a ball of the player's paint where their blob is looking. A clean
## blob only puffs, which nudges a child towards a puddle without a rule to
## explain. Returns the ball, or null when nothing flew.
func throw_splat(player: PaintPlayer) -> SplatBall:
	if player.seconds_until_next_throw > 0.0:
		return null
	player.seconds_until_next_throw = THROW_COOLDOWN_SECONDS
	var thrower_blob: MeadowBlob = player.blob
	thrower_blob.look.squash_stretch.kick(Vector2(-10, 10))
	if player.paint_bits == 0:
		PaintSplash.burst(effects_layer, thrower_blob.position + thrower_blob.look.look_direction * 50.0, Color.WHITE, 6, 180)
		Sound.play("wobble")
		return null
	var ball: SplatBall = SplatBall.new()
	ball.thrower = player
	ball.paint_bits = player.paint_bits
	ball.paint_colour = PaintMixing.colour_of(thrower_blob.paint_name)
	ball.start_position = thrower_blob.position
	var facing: Vector2 = thrower_blob.look.look_direction.normalized()
	var aimed_at: Node2D = best_aim_target(player, facing)
	var landing_spot: Vector2 = aimed_at.position if aimed_at != null else thrower_blob.position + facing * THROW_DISTANCE
	ball.landing_position = clamp_to_landing_area(landing_spot)
	ball.position = ball.start_position
	effects_layer.add_child(ball)
	balls.append(ball)
	Sound.play("jump")
	return ball


func clamp_to_landing_area(point: Vector2) -> Vector2:
	return point.clamp(LANDING_AREA.position, LANDING_AREA.end)


## Everything this player's splat can hit: the other player and the pals.
func splat_targets(thrower: PaintPlayer) -> Array[Node2D]:
	var targets: Array[Node2D] = []
	for pal in pals:
		targets.append(pal)
	for thing in things:
		targets.append(thing)
	for player in players:
		if player != thrower:
			targets.append(player.blob)
	return targets


## The nearest to straight ahead of whoever is within the cone and range.
func best_aim_target(thrower: PaintPlayer, facing: Vector2) -> Node2D:
	var best: Node2D = null
	var best_angle: float = AIM_CONE_RADIANS
	for target in splat_targets(thrower):
		var to_target: Vector2 = target.position - thrower.blob.position
		if to_target == Vector2.ZERO or to_target.length() > AIM_RANGE:
			continue
		var angle: float = absf(facing.angle_to(to_target))
		if angle < best_angle:
			best_angle = angle
			best = target
	return best


func target_near(ball: SplatBall) -> Node2D:
	for target in splat_targets(ball.thrower):
		if target.position.distance_to(ball.position) < HIT_RADIUS:
			return target
	return null


## A splat that hits someone lands at their feet and mixes into their paint.
## No knockback and no thud: a hit is a gift.
func land_ball(ball: SplatBall, struck: Node2D) -> void:
	balls.erase(ball)
	ball.queue_free()
	var landing_spot: Vector2 = ball.position if struck == null else struck.position + BRUSH_OFFSET
	canvas.splat(landing_spot, ball.paint_bits, ball.thrower.brush_number)
	PaintSplash.burst(effects_layer, landing_spot, ball.paint_colour, 16, 560)
	Sound.play("splat")
	if struck != null:
		mix_into(struck, ball.paint_bits)


func paint_bits_of(target: Node2D) -> int:
	if target is SplatPal or target is SplatThing:
		return target.paint_bits
	return player_of(target).paint_bits


func mix_into(target: Node2D, splat_bits: int) -> void:
	var bits_before: int = paint_bits_of(target)
	var bits_after: int = PaintMixing.mix_bits(bits_before, splat_bits)
	if bits_after == bits_before:
		target_wobble(target, Vector2(-6, 6))
		return
	var paint_before: String = PaintMixing.paint_made_of(bits_before, colour_set)
	var paint_after: String = PaintMixing.paint_made_of(bits_after, colour_set)
	var splat_paint: String = PaintMixing.paint_made_of(splat_bits, colour_set)
	give_paint(target, bits_after, paint_after)
	PaintSplash.burst(effects_layer, target.position, PaintMixing.colour_of(splat_paint), 18, 560)
	Sound.play("pick")
	if GameSettings.record_found("colours_found", paint_after):
		PuddleFriend.say_hello(effects_layer, target.position, paint_after, paint_before, splat_paint)


func give_paint(target: Node2D, bits: int, paint: String) -> void:
	if target is SplatPal or target is SplatThing:
		target.take_paint(bits, paint)
		return
	player_of(target).paint_bits = bits
	target.change_paint(paint)


func target_wobble(target: Node2D, amount: Vector2) -> void:
	if target is SplatThing:
		target.wobble()
		return
	target.look.squash_stretch.kick(amount)


## The sponge gives everyone a fresh start, pals and word characters included.
func wipe_picture() -> void:
	super()
	for pal in pals:
		pal.wash()
	for thing in things:
		thing.wash()
