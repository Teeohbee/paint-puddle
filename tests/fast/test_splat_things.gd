extends GameSuite
func settle():
	await get_tree().process_frame
	await get_tree().process_frame
func fly(frames):
	for frame in frames:
		await get_tree().physics_frame
func test_splat_things() -> void:
	var settings = GameSettings
	settings.load_from_disk()
	get_tree().change_scene_to_file("res://paint/splat_party.tscn")
	await settle()
	var party = get_tree().current_scene
	check(party.things.size() == 3, "three word characters wander about")
	var distinct = {}
	for t in party.things: distinct[t.thing_name] = true
	check(distinct.size() == 3, "all different")
	var thing = party.things[0]
	for other in party.things + party.pals:
		if other != thing: other.position = Vector2(1700, 100)
	thing.set_process(false)
	thing.position = Vector2(900, 400)
	var one = party.players[0]
	one.blob.position = Vector2(500, 400)
	one.blob.look.look_direction = Vector2.RIGHT
	var red = PaintMixing.bits_of("red", "paint")
	one.paint_bits = red
	one.blob.change_paint("red")
	var ball = party.throw_splat(one)
	check(ball != null and ball.landing_position.is_equal_approx(Vector2(900, 400)), "throw aims at the character")
	await fly(40)
	check(thing.paint_bits == red, "a red hit turns it red")
	check(thing.picture.modulate != Color.WHITE, "and tints the picture")
	party.wipe_picture()
	await fly(5)
	check(thing.paint_bits == 0 and thing.picture.modulate == Color.WHITE, "sponge washes it")
	var oldest = party.things[0]
	party.swap_oldest_thing()
	check(party.things.size() == 3 and not party.things.has(oldest), "a swap sends the oldest off and brings one in")
	var names = {}
	for t in party.things: names[t.thing_name] = true
	check(names.size() == 3, "still all different")
	check(oldest.is_leaving, "the leaver waves goodbye")
