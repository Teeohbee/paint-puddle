extends GameSuite
# Sea life on the world screen in Map mode: under the land, twelve boats moving, kept away from the pin,
# held during zooms, absent on continents, and the pin's hit-testing unchanged.

func test_sea_life_map() -> void:
	var settings = GameSettings
	settings.load_from_disk()
	get_tree().change_scene_to_file("res://map/map_mode.tscn")
	await frames(4)
	var mode = get_tree().current_scene
	var sea = mode.screen.get_node_or_null("SeaLife")
	check(sea != null and sea.get_index() == 0, "sea life is the world screen's first child, under the land")
	check(sea.boats.size() == 12, "twelve boats on the world")
	# Distance along each lane, added up frame by frame. Comparing x alone could miss a boat that
	# turned round at the end of its lane, or one on a lane that runs mostly up and down.
	var travelled = []
	travelled.resize(sea.boats.size())
	travelled.fill(0.0)
	for frame in 60:
		var before = sea.boats.map(func(b): return b.along)
		await get_tree().physics_frame
		await get_tree().process_frame
		for i in sea.boats.size():
			var boat = sea.boats[i]
			travelled[i] += absf(boat.along - before[i]) * boat.lane_from.distance_to(boat.lane_to)
	var moved = travelled.filter(func(distance): return distance > 3.0).size()
	check(moved == 12, "every boat moves along: %d, distances %s" % [moved, travelled.map(func(d): return snappedf(d, 0.1))])

	mode.pointer.position = Vector2(820, 720)
	var avoid = sea.avoid_points.call()
	check(avoid.size() == 1 and avoid[0] == Vector2(820, 720), "the pin is kept clear of: %s" % [avoid])
	check(not sea.open_spots().has(Vector2(820, 720)), "spots by the pin aren't used")
	mode.hint_arrow.visible = true
	mode.hint_arrow.origin = Vector2(820, 720)
	mode.hint_arrow.angle = 0.0
	check(sea.avoid_points.call().size() == 2, "the hint arrow is kept clear of too while it shows")
	mode.hint_arrow.visible = false

	# hit-testing: the same targets with sea life as without it
	var with_sea = []
	for y in range(20, 1080, 40):
		for x in range(20, 1920, 40): with_sea.append(mode.screen.target_at(Vector2(x, y)))
	sea.free()
	var without_sea = []
	for y in range(20, 1080, 40):
		for x in range(20, 1920, 40): without_sea.append(mode.screen.target_at(Vector2(x, y)))
	check(with_sea == without_sea and with_sea.has("europe") and with_sea.has(""), "the pin picks the same things with or without sea life")

	# zooms: held during a zoom, none on a continent, back again on the world
	mode.zoom_to("africa")
	await frames(30)
	check(mode.screen_name == "africa" and mode.screen.get_node_or_null("SeaLife") == null, "no sea life on a continent")
	mode.zoom_to("world")
	var held_mid_zoom = false
	for i in 40:
		await get_tree().physics_frame
		var world_sea = mode.screen.get_node_or_null("SeaLife")
		if world_sea != null and mode.is_changing_screen: held_mid_zoom = world_sea.is_held.call()
	check(held_mid_zoom, "held while the world zooms in")
	var back = mode.screen.get_node_or_null("SeaLife")
	check(back != null and not back.is_held.call() and back.boats.size() == 12, "back on the world, sea life again and not held")
