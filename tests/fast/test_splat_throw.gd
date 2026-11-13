extends GameSuite
# A flings a splat of the blob's paint ahead of it; a clean blob only puffs; the
# cooldown holds; each pad's A throws for its own blob.

func settle():
	await get_tree().process_frame
	await get_tree().process_frame

func pad_a(device, pressed):
	var event = InputEventJoypadButton.new()
	event.device = device
	event.button_index = JOY_BUTTON_A
	event.pressed = pressed
	return event

func tap_a(device):
	Input.parse_input_event(pad_a(device, true))
	await settle()
	Input.parse_input_event(pad_a(device, false))
	await settle()

func paint_cells(party):
	var count = 0
	for cell in party.canvas.cells:
		if cell != 0: count += 1
	return count

func test_splat_throw() -> void:
	var settings = GameSettings
	settings.load_from_disk()
	PlayerSession.choose_one_player()
	get_tree().change_scene_to_file("res://paint/splat_party.tscn")
	await settle()
	var party = get_tree().current_scene
	# The pals and word characters wander at random; park them out of the way
	for pal in party.pals + party.things:
		pal.set_process(false)
		pal.position = Vector2(1850, 60)
	var one = party.players[0]
	one.blob.position = Vector2(600, 500)
	one.blob.look.look_direction = Vector2.RIGHT
	var red = PaintMixing.bits_of("red", "paint")

	# Clean blob: nothing flies
	check(party.throw_splat(one) == null and party.balls.is_empty(), "a clean blob throws nothing")
	one.seconds_until_next_throw = 0.0

	# Painted blob: a ball flies, then paints ahead of it
	one.paint_bits = red
	one.blob.change_paint("red")
	var ball = party.throw_splat(one)
	check(ball != null and party.balls.size() == 1, "a red blob throws a ball")
	check(party.throw_splat(one) == null, "the cooldown stops a second throw straight away")
	check(paint_cells(party) == 0, "nothing is on the paper while the ball is in the air")
	for frame in 40:
		await get_tree().physics_frame
	check(party.balls.is_empty(), "the ball lands")
	var landing = Vector2(600, 500) + Vector2.RIGHT * party.THROW_DISTANCE
	check(party.canvas.paint_at(landing) == "red", "and paints red %d px ahead: %s" % [party.THROW_DISTANCE, party.canvas.paint_at(landing)])
	check(party.canvas.paint_at(Vector2(600, 500)) == "clean", "not under the blob")
	check(one.paint_bits == red, "throwing doesn't use up the paint")

	# The cooldown ends
	for frame in 30:
		await get_tree().physics_frame
	check(one.seconds_until_next_throw == 0.0, "the cooldown runs out")

	# Splats stay above the puddle row
	one.blob.position = Vector2(960, 700)
	one.blob.look.look_direction = Vector2.DOWN
	var down_ball = party.throw_splat(one)
	check(down_ball.landing_position.y <= party.LANDING_AREA.end.y, "a throw down the screen falls short of the puddles: %.0f" % down_ball.landing_position.y)
	for frame in 40:
		await get_tree().physics_frame

	# Input: A on a pad throws; with two players, each pad throws for its own blob
	one.seconds_until_next_throw = 0.0
	one.blob.position = Vector2(400, 300)
	one.blob.look.look_direction = Vector2.RIGHT
	await tap_a(0)
	check(party.balls.size() == 1, "A on the only pad throws for player one")
	for frame in 40:
		await get_tree().physics_frame
	PlayerSession.choose_two_players(0, 1)
	party.add_player_two()
	await settle()
	check(party.players.size() == 2, "a second pad brings in player two")
	var two = party.players[1]
	two.paint_bits = PaintMixing.bits_of("blue", "paint")
	two.blob.change_paint("blue")
	two.blob.position = Vector2(1400, 300)
	two.blob.look.look_direction = Vector2.LEFT
	one.seconds_until_next_throw = 0.0
	two.seconds_until_next_throw = 0.0
	await tap_a(1)
	check(party.balls.size() == 1 and party.balls[0].thrower == two, "A on pad 2 throws only player two's splat")
	for frame in 40:
		await get_tree().physics_frame
	one.seconds_until_next_throw = 0.0
	await tap_a(0)
	check(party.balls.size() == 1 and party.balls[0].thrower == one, "A on pad 1 throws only player one's splat")
