extends GameSuite
# Map mode: the world screen of seven continents, zooming into one, every country on it, the pin pointer's
# tip picking what's under it, the globe back out, straddlers on both screens, the gentle magnet pull.

var picked = []
func press_a():
	Input.action_press("act")
	await frames(2)
	Input.action_release("act")
	await frames(2)

func label_of(mode, target):
	for shape in mode.screen.shapes:
		if shape.target_id == target: return shape.label_position
	return null

func test_map_mode() -> void:
	var settings = GameSettings
	settings.load_from_disk()
	get_tree().change_scene_to_file("res://map/map_mode.tscn")
	await frames(4)
	var mode = get_tree().current_scene
	mode.country_picked.connect(func(id): picked.append(id))

	# ---- the world screen
	check(mode.screen_name == "world", "starts on the world screen")
	var continent_ids = {}
	for shape in mode.screen.shapes: continent_ids[shape.target_id] = true
	check(continent_ids.size() == 7, "seven continents on the world: %s" % [continent_ids.keys()])
	check(mode.screen.magnets.is_empty(), "no magnet pull on the world screen")
	check(mode.target_under_pointer == "europe" and mode.name_label.text == "Europe", "the pointer starts over Europe: '%s'" % mode.name_label.text)
	var russia_east = mode.screen.target_at(Vector2(1500, 200))
	check(russia_east == "asia", "east Russia is Asia on the world screen: '%s'" % russia_east)
	mode.pointer.position = Vector2(300, 900)
	await frames(3)
	check(mode.target_under_pointer == "" and not mode.name_pill.visible, "over the sea there is no name")
	await press_a()
	check(mode.screen_name == "world" and picked.is_empty(), "A over the sea does nothing")

	mode.pointer.position = label_of(mode, "antarctica")
	await frames(3)
	await press_a()
	check(picked == ["antarctica"], "Antarctica is picked straight from the world: %s" % [picked])
	picked.clear()

	# ---- the continent names stay on top however many continents the pointer has been over
	for continent in ["africa", "asia", "north_america", "south_america", "europe", "oceania"]:
		mode.pointer.position = label_of(mode, continent)
		await frames(3)
	var topmost = mode.screen.get_child(mode.screen.get_child_count() - 1)
	check("labels" in topmost and topmost.labels.size() == 7, "the continent names are still the top layer")

	# ---- Russia's far-west sliver (over the date line) is Asia, not Europe
	var europe_far_west: bool = false
	for shape in mode.screen.shapes:
		if shape.target_id == "europe" and shape.bounds.position.x < 500.0:
			europe_far_west = true
	check(not europe_far_west, "no Europe on the far west of the world screen")

	# ---- the world goes round: off the right edge comes back on the left
	mode.pointer.position = Vector2(1900, 600)
	Input.action_press("move_right")
	await frames(40)
	Input.action_release("move_right")
	check(mode.pointer.position.x < 400.0 and mode.pointer.position.x >= 0.0, "driving off the right edge comes back on the left: %.0f" % mode.pointer.position.x)
	mode.pointer.position = Vector2(20, 600)
	Input.action_press("move_left")
	await frames(40)
	Input.action_release("move_left")
	check(mode.pointer.position.x > 1500.0, "and off the left comes back on the right: %.0f" % mode.pointer.position.x)

	await frames(30)
	mode.pointer.velocity = Vector2.ZERO
	# ---- zoom into Europe
	mode.pointer.position = label_of(mode, "europe")
	await frames(3)
	check(mode.target_under_pointer == "europe", "over Europe")
	await press_a()
	await frames(50)
	check(mode.screen_name == "europe" and not mode.is_changing_screen, "A zooms into Europe")
	check(mode.screen.shapes.size() == 48, "every European country is on the screen: %d" % mode.screen.shapes.size())
	check(mode.globe_button.visible, "the globe is there to zoom back out")
	check(mode.screen.magnets.size() == 48, "each country is a magnet")

	var france = label_of(mode, "france")
	mode.pointer.position = france
	await frames(3)
	check(mode.target_under_pointer == "france" and mode.name_label.text == "France" and mode.name_pill.visible, "the tip over France shows France")
	check(mode.screen.shapes.filter(func(s): return s.is_highlighted).size() == 1, "only France is ringed")
	await press_a()
	check(picked == ["france"], "A picks the country under the tip: %s" % [picked])
	picked.clear()

	# ---- straddlers are on both screens
	var russia = label_of(mode, "russia")
	check(russia != null and mode.screen.target_at(russia) == "russia", "Russia is on the Europe screen")
	check(label_of(mode, "turkey") != null, "Turkey is on the Europe screen")

	# ---- the gentle magnet pull
	var spain_label = label_of(mode, "spain")
	mode.pointer.position = spain_label + Vector2(55, 0)
	await frames(60)
	check(mode.pointer.position.distance_to(spain_label) < 12.0, "let go near a country and the pointer drifts to its middle: %s" % mode.pointer.position.distance_to(spain_label))
	mode.pointer.position = Vector2(150, 900)
	mode.pointer.velocity = Vector2.ZERO
	await frames(30)
	check(mode.pointer.position.is_equal_approx(Vector2(150, 900)), "nothing pulls it from open sea")
	mode.pointer.position = spain_label + Vector2(55, 0)
	Input.action_press("move_right")
	await frames(20)
	Input.action_release("move_right")
	check(mode.pointer.position.x > spain_label.x + 55, "holding the D-pad overrides the pull")

	# ---- keep inside the screen
	mode.pointer.position = Vector2(-900, -900)
	await frames(2)
	check(mode.pointer.position.x >= 40 and mode.pointer.position.y >= 40, "the pointer can't leave the screen")

	# ---- the pin turns over at the top so its head stays on screen
	mode.pointer.position = Vector2(1700, 100)
	await frames(2)
	var flip_probe = mode.pointer.HEAD_FLIPS_BELOW_Y
	check(mode.pointer.position.y < flip_probe, "the pointer is up in the globe's corner")

	# ---- the globe zooms back out
	mode.pointer.position = Vector2(1700, 100)
	await frames(3)
	check(mode.globe_button.is_hovered and mode.target_under_pointer == "", "the pointer over the globe hovers it")
	await press_a()
	await frames(50)
	check(mode.screen_name == "world", "the globe zooms back out")
	check(mode.target_under_pointer == "europe", "landing back over Europe: '%s'" % mode.target_under_pointer)

	# ---- Asia shows Russia too
	mode.pointer.position = label_of(mode, "asia")
	await frames(3)
	await press_a()
	await frames(50)
	check(mode.screen_name == "asia", "A zooms into Asia")
	var russia_in_asia = label_of(mode, "russia")
	check(russia_in_asia != null and mode.screen.target_at(russia_in_asia) == "russia", "Russia is on the Asia screen too")
	check(label_of(mode, "egypt") != null, "Egypt is on the Asia screen too")

	# ---- painting
	var shape = mode.screen.shapes[0]
	var pale = shape.fills[0].color
	mode.screen.paint_country(shape.target_id)
	check(shape.fills[0].color != pale and shape.fills[0].color.is_equal_approx(shape.rainbow_colour), "painting gives a country its full colour")
