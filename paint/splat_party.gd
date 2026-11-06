class_name SplatParty
extends PaintStudio
## Splat party: Paint's paper, puddles, fountain and sponge, but moving
## doesn't paint. A flings a splat of the blob's paint instead.

var paint_colour_set_before: String = ""


func _init() -> void:
	paints_trails = false
	# Paint colours only; put the Paint menu's choice back on the way out
	paint_colour_set_before = PaintStudio.colour_set
	PaintStudio.colour_set = "paint"


func _exit_tree() -> void:
	PaintStudio.colour_set = paint_colour_set_before


func configure_controls_hint() -> void:
	controls_hint.shows_jump = false
	controls_hint.shows_act_button = true


const THROW_DISTANCE: float = 420.0
const THROW_COOLDOWN_SECONDS: float = 0.35
## Splats land on the paper above the puddle row, so they fall short of it.
const LANDING_AREA: Rect2 = Rect2(40, 40, 1840, 790)

var balls: Array[SplatBall] = []


func add_player_two(device: int) -> void:
	super(device)
	# Each pad's A throws for its own blob, like the sticks move their own
	players[0].act_action = PlayerControls.make_pad_act_action("player_one", player_one_device, true)
	players[1].act_action = PlayerControls.make_pad_act_action("player_two", device, false)


func _physics_process(delta: float) -> void:
	super(delta)
	for player in players:
		player.seconds_until_next_throw = maxf(0.0, player.seconds_until_next_throw - delta)
		if Input.is_action_just_pressed(player.act_action):
			throw_splat(player)
	for ball in balls.duplicate():
		ball.advance(delta)
		if ball.has_landed():
			land_ball(ball)


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
	ball.landing_position = clamp_to_landing_area(thrower_blob.position + thrower_blob.look.look_direction.normalized() * THROW_DISTANCE)
	ball.position = ball.start_position
	effects_layer.add_child(ball)
	balls.append(ball)
	Sound.play("jump")
	return ball


func clamp_to_landing_area(point: Vector2) -> Vector2:
	return point.clamp(LANDING_AREA.position, LANDING_AREA.end)


func land_ball(ball: SplatBall) -> void:
	balls.erase(ball)
	ball.queue_free()
	canvas.splat(ball.position, ball.paint_bits, ball.thrower.brush_number)
	PaintSplash.burst(effects_layer, ball.position, ball.paint_colour, 16, 560)
	Sound.play("splat")
