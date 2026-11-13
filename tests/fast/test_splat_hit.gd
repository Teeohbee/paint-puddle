extends GameSuite
# Splats head for a blob nearly straight ahead and mix into it when they hit.
# A wide miss mixes nothing. Hits are saved to the Book.

func settle():
	await get_tree().process_frame
	await get_tree().process_frame

func pad_a(device):
	var event = InputEventJoypadButton.new()
	event.device = device
	event.button_index = JOY_BUTTON_A
	event.pressed = true
	return event

func fly(frames):
	for frame in frames:
		await get_tree().physics_frame

func test_splat_hit() -> void:
	var settings = GameSettings
	settings.load_from_disk()
	PlayerSession.choose_two_players(0, 1)
	get_tree().change_scene_to_file("res://paint/splat_party.tscn")
	await settle()
	var party = get_tree().current_scene
	# The pals and word characters wander at random; park them out of the way
	for pal in party.pals + party.things:
		pal.set_process(false)
		pal.position = Vector2(1850, 60)
	await settle()
	var one = party.players[0]
	var two = party.players[1]
	var red = PaintMixing.bits_of("red", "paint")
	var blue = PaintMixing.bits_of("blue", "paint")
	one.paint_bits = blue
	one.blob.change_paint("blue")
	two.paint_bits = red
	two.blob.change_paint("red")

	# Aim assist: player two is a little off to one side, 500 px away
	one.blob.position = Vector2(400, 400)
	one.blob.look.look_direction = Vector2.RIGHT
	two.blob.position = Vector2(900, 460)
	var ball = party.throw_splat(one)
	check(ball.landing_position.distance_to(two.blob.position) < 1.0, "a throw at someone nearly straight ahead heads for them")
	await fly(40)
	check(two.paint_bits == (red | blue), "the hit mixes blue into red")
	check(two.blob.paint_name == "purple", "and their blob turns purple: %s" % two.blob.paint_name)
	check(one.paint_bits == blue, "the thrower is unchanged")
	check(party.canvas.paint_at(two.blob.position + party.BRUSH_OFFSET) == "blue", "the splat lands at their feet")
	check(settings.has_found("colours_found", "purple"), "purple is saved to the Book")

	# Same colour again: nothing changes, nobody is hurt
	one.seconds_until_next_throw = 0.0
	party.throw_splat(one)
	await fly(40)
	check(two.paint_bits == (red | blue), "hitting purple with blue changes nothing")

	# Too far to one side: flies straight, misses, mixes nothing
	two.paint_bits = red
	two.blob.change_paint("red")
	two.blob.position = Vector2(900, 800)
	one.seconds_until_next_throw = 0.0
	ball = party.throw_splat(one)
	check(ball.landing_position.is_equal_approx(Vector2(400, 400) + Vector2.RIGHT * party.THROW_DISTANCE), "someone well off to one side isn't aimed at")
	await fly(40)
	check(two.paint_bits == red, "a wide miss mixes nothing")

	# Out of range: not aimed at
	two.blob.position = Vector2(1500, 400)
	one.seconds_until_next_throw = 0.0
	ball = party.throw_splat(one)
	check(ball.landing_position.x < 1000, "someone too far away isn't aimed at")
	await fly(40)

	# Walking into a flying ball counts
	two.blob.position = Vector2(700, 440)
	one.blob.position = Vector2(400, 400)
	one.seconds_until_next_throw = 0.0
	ball = party.throw_splat(one)
	two.blob.position = Vector2(700, 400)
	await fly(40)
	check(two.paint_bits == (red | blue), "stepping into the path of a ball gets you splatted")

	# A blob can't hit itself
	one.paint_bits = red
	one.blob.change_paint("red")
	one.blob.position = Vector2(300, 300)
	two.blob.position = Vector2(1500, 900)
	one.seconds_until_next_throw = 0.0
	party.throw_splat(one)
	await fly(40)
	check(one.paint_bits == red, "you can't splat yourself")
