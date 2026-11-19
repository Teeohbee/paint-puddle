extends GameSuite
# Clock mode's scene: the clock starts at 7 am, left and right wind it a rung's step at a time,
# holding winds quicker, and the hands sweep to where they're wound.

func open_clock_mode() -> ClockMode:
	get_tree().change_scene_to_file("res://clock/clock_mode.tscn")
	await frames(4)
	return get_tree().current_scene

func hold(action: String, frame_count: int) -> void:
	Input.action_press(action)
	await frames(frame_count)
	Input.action_release(action)
	await frames(2)

func test_the_clock_starts_at_7_in_the_morning() -> void:
	var mode: ClockMode = await open_clock_mode()
	check(mode.minutes_of_the_day() == 7 * 60, "starts at 7 am, is %s" % ClockTime.digital_text(mode.minutes_of_the_day()))

func test_a_tap_winds_one_step_each_way() -> void:
	var mode: ClockMode = await open_clock_mode()
	await hold("move_right", 2)
	check(mode.minutes_of_the_day() == 7 * 60 + 30, "right winds on half an hour: %s" % ClockTime.digital_text(mode.minutes_of_the_day()))
	await hold("move_left", 2)
	await hold("move_left", 2)
	check(mode.minutes_of_the_day() == 6 * 60 + 30, "left winds back: %s" % ClockTime.digital_text(mode.minutes_of_the_day()))

func test_holding_winds_many_steps_and_the_hands_catch_up() -> void:
	var mode: ClockMode = await open_clock_mode()
	await hold("move_right", 90)
	var steps_wound: int = (mode.wound_minutes - 7 * 60) / 30
	check(steps_wound > 8, "a 1.5 s hold winds lots of steps: %d" % steps_wound)
	await frames(60)
	check(not mode.clock_face.is_sweeping() and is_equal_approx(mode.clock_face.shown_minutes, mode.wound_minutes), "the hands settle where they're wound")

func test_the_play_menu_has_a_clock_tile_that_opens_clock_mode() -> void:
	get_tree().change_scene_to_file("res://ui/play_menu.tscn")
	await frames(4)
	var clock_tile = null
	for tile in get_tree().current_scene.find_children("*", "MenuTile", true, false):
		if tile.word == "Clock": clock_tile = tile
	check(clock_tile != null, "there's a Clock tile")
	clock_tile.chosen.emit()
	await frames(40)
	check(get_tree().current_scene is ClockMode, "it opens Clock mode")
