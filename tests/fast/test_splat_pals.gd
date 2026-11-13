extends GameSuite
# Wandering pals to splat: three of them, clean to start, mixing like players, washed by the sponge.

func settle():
	await get_tree().process_frame
	await get_tree().process_frame

func fly(frames):
	for frame in frames:
		await get_tree().physics_frame

func test_splat_pals() -> void:
	var settings = GameSettings
	settings.load_from_disk()
	get_tree().change_scene_to_file("res://paint/splat_party.tscn")
	await settle()
	var party = get_tree().current_scene
	check(party.pals.size() == 3, "three pals wander about")
	var all_clean = true
	var all_on_paper = true
	for pal in party.pals:
		all_clean = all_clean and pal.paint_bits == 0
		all_on_paper = all_on_paper and Rect2(0, 0, 1920, 830).has_point(pal.position)
	check(all_clean, "they start clean")
	check(all_on_paper, "and start above the puddle row")
	var one = party.players[0]
	var red = PaintMixing.bits_of("red", "paint")
	var yellow = PaintMixing.bits_of("yellow", "paint")
	var pal = party.pals[0]
	# Keep the others out of the way and the pal still
	for other in party.pals + party.things:
		if other != pal:
			other.position = Vector2(1700, 100)
	pal.set_process(false)
	pal.position = Vector2(900, 400)
	one.blob.position = Vector2(500, 400)
	one.blob.look.look_direction = Vector2.RIGHT

	one.paint_bits = red
	one.blob.change_paint("red")
	var ball = party.throw_splat(one)
	check(ball != null and ball.landing_position.is_equal_approx(Vector2(900, 400)), "a throw at a pal ahead heads for it")
	await fly(40)
	check(pal.paint_bits == red, "a red hit turns the pal red")
	one.paint_bits = yellow
	one.blob.change_paint("yellow")
	one.seconds_until_next_throw = 0.0
	party.throw_splat(one)
	await fly(40)
	check(pal.paint_bits == (red | yellow), "then a yellow hit makes it orange")
	check(settings.has_found("colours_found", "orange"), "and orange is saved to the Book")

	# Wipe washes everyone
	party.wipe_picture()
	check(pal.paint_bits == 0, "the sponge washes the pal clean")
	var every_pal_clean = true
	for other in party.pals:
		every_pal_clean = every_pal_clean and other.paint_bits == 0
	check(every_pal_clean, "all of them")
