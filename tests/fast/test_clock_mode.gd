extends GameSuite
# Clock mode's scene: the clock starts at 7 am, left and right wind it a rung's step at a time,
# holding winds quicker, and the hands sweep to where they're wound.

## Opens Clock mode on a set card for 9 in the morning, so left and right wind the hands.
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

func test_the_play_menu_has_a_clock_tile_that_opens_the_clock_menu() -> void:
	get_tree().change_scene_to_file("res://ui/play_menu.tscn")
	await frames(4)
	var clock_tile = null
	for tile in get_tree().current_scene.find_children("*", "MenuTile", true, false):
		if tile.word == "Clock": clock_tile = tile
	check(clock_tile != null, "there's a Clock tile")
	clock_tile.chosen.emit()
	await frames(40)
	check(get_tree().current_scene.scene_file_path == "res://ui/clock_menu.tscn", "it opens the Clock menu")

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
	await hold("move_left", 2)
	check(mode.minutes_of_the_day() % 5 == 4, "and a tap counts a single minute back: %s" % ClockTime.digital_text(mode.minutes_of_the_day()))
