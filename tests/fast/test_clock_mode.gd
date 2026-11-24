extends GameSuite
# Clock mode's scene: the clock starts at 7 am, right winds it on a rung's step at a time (time only
# goes forward, so left does nothing), holding winds quicker, the hands sweep to where they're wound,
# and the word under the clock says the part of the day.

## Opens Clock mode on a set card for 9 in the morning, so right winds the hands.
func open_clock_mode() -> ClockMode:
	get_tree().change_scene_to_file("res://clock/clock_mode.tscn")
	await frames(4)
	var mode: ClockMode = get_tree().current_scene
	var set_card_deck: Array[ClockCard] = [ClockCard.new(false, 9 * 60)]
	mode.task_runner.start_deck(3, set_card_deck)
	return mode

func hold(action: String, frame_count: int) -> void:
	Input.action_press(action)
	await frames(frame_count)
	Input.action_release(action)
	await frames(2)

func test_the_clock_starts_at_7_in_the_morning() -> void:
	get_tree().change_scene_to_file("res://clock/clock_mode.tscn")
	await frames(2)
	var mode: ClockMode = get_tree().current_scene
	check(mode.clock_face.shown_minutes < 7 * 60 + 60, "the day starts at 7 am: the hands are at %s" % ClockTime.digital_text(int(mode.clock_face.shown_minutes)))
	check(mode.wound_minutes >= 7 * 60, "and the first read card winds forwards from it")

func test_right_winds_on_and_left_does_nothing() -> void:
	var mode: ClockMode = await open_clock_mode()
	await hold("move_right", 2)
	check(mode.minutes_of_the_day() == 7 * 60 + 30, "right winds on half an hour: %s" % ClockTime.digital_text(mode.minutes_of_the_day()))
	await hold("move_left", 2)
	await hold("move_left", 30)
	check(mode.minutes_of_the_day() == 7 * 60 + 30, "left doesn't wind back: %s" % ClockTime.digital_text(mode.minutes_of_the_day()))

func test_the_word_under_the_clock_follows_the_hands() -> void:
	var mode: ClockMode = await open_clock_mode()
	await frames(2)
	check(mode.day_label.word == "morning", "7am is the morning: '%s'" % mode.day_label.word)
	for step in 12:
		await hold("move_right", 2)
	await frames(60)
	check(mode.day_label.word == "afternoon", "1pm is the afternoon: '%s'" % mode.day_label.word)
	for step in 12:
		await hold("move_right", 2)
	await frames(60)
	check(mode.day_label.word == "evening", "7pm is the evening: '%s'" % mode.day_label.word)
	for step in 4:
		await hold("move_right", 2)
	await frames(60)
	check(mode.day_label.word == "night", "9pm is night: '%s'" % mode.day_label.word)

func test_holding_winds_many_steps_and_the_hands_catch_up() -> void:
	var mode: ClockMode = await open_clock_mode()
	await hold("move_right", 90)
	var steps_wound: int = (mode.wound_minutes - 7 * 60) / 30
	check(steps_wound > 8, "a 1.5 s hold winds lots of steps: %d" % steps_wound)
	await frames(60)
	check(not mode.clock_face.is_sweeping() and is_equal_approx(mode.clock_face.shown_minutes, mode.wound_minutes), "the hands settle where they're wound")

# Clock mode is under construction: its tile is taped off and says it'll be back soon
func test_the_play_menu_clock_tile_is_under_construction() -> void:
	get_tree().change_scene_to_file("res://ui/play_menu.tscn")
	await frames(4)
	var clock_tile = null
	for tile in get_tree().current_scene.find_children("*", "MenuTile", true, false):
		if tile.word == "Clock": clock_tile = tile
	check(clock_tile != null, "there's a Clock tile")
	check(clock_tile.is_under_construction and clock_tile.is_locked and not clock_tile.shows_padlock, "taped off, locked, no padlock")
	check(clock_tile.subtitle == "Be back soon!", "says it'll be back: " + clock_tile.subtitle)
	clock_tile.pressed.emit()
	await frames(40)
	check(get_tree().current_scene.scene_file_path == "res://ui/play_menu.tscn", "pressing it stays on the play menu")

func test_rung_8_taps_count_minutes_and_a_hold_goes_in_fives() -> void:
	get_tree().change_scene_to_file("res://clock/clock_mode.tscn")
	await frames(4)
	var mode: ClockMode = get_tree().current_scene
	var set_card_deck: Array[ClockCard] = [ClockCard.new(false, 9 * 60 + 17)]
	mode.task_runner.start_deck(8, set_card_deck)
	await frames(2)
	await hold("move_right", 2)
	await hold("move_right", 2)
	check(mode.minutes_of_the_day() == 7 * 60 + 2, "two taps are two minutes: %s" % ClockTime.digital_text(mode.minutes_of_the_day()))
	await hold("move_right", 60)
	var minute: int = mode.minutes_of_the_day() % 60
	check(minute % 5 == 0 and minute >= 5, "a hold snaps to the fives: %s" % ClockTime.digital_text(mode.minutes_of_the_day()))
	var before_left: int = mode.minutes_of_the_day()
	await hold("move_left", 2)
	check(mode.minutes_of_the_day() == before_left, "and left does nothing here either")
