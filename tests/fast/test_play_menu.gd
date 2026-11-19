extends GameSuite
# The play menu: places in two rows, left and right reading through both, up and down between them.

func press(action):
	var event = InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await get_tree().process_frame
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	await frames(2)

func focused_word():
	var owner = get_tree().root.gui_get_focus_owner()
	return owner.word if owner != null and "word" in owner else "(nothing)"

func tile(word):
	for each in get_tree().current_scene.find_children("*", "MenuTile", true, false):
		if each.word == word: return each
	return null

func open_play_menu():
	MenuScreen.last_choices.erase("play_menu")
	get_tree().change_scene_to_file("res://ui/play_menu.tscn")
	await frames(4)

func test_the_tiles_sit_in_two_rows_on_screen() -> void:
	await open_play_menu()
	var top_row = ["Back", "Meadow", "Hills", "Paint", "Splat"]
	var bottom_row = ["Map", "Clock", "Book", "1 Player"]
	var top_y = tile("Meadow").get_global_rect().get_center().y
	var bottom_y = tile("Map").get_global_rect().get_center().y
	check(bottom_y > top_y + 150, "the second row is below the first: %s vs %s" % [top_y, bottom_y])
	for word in top_row:
		check(absf(tile(word).get_global_rect().get_center().y - top_y) < 1.0, "%s is in the top row" % word)
	for word in bottom_row:
		check(absf(tile(word).get_global_rect().get_center().y - bottom_y) < 1.0, "%s is in the bottom row" % word)
	var screen = Rect2(Vector2.ZERO, Vector2(1920, 1080))
	for word in top_row + bottom_row:
		check(screen.encloses(tile(word).get_global_rect()), "%s is on the screen" % word)

func test_right_reads_through_both_rows_and_left_comes_back() -> void:
	await open_play_menu()
	var reading_order = ["Meadow", "Hills", "Paint", "Splat", "Map", "Clock", "Book", "1 Player"]
	check(focused_word() == "Meadow", "starts on Meadow: " + focused_word())
	for word in reading_order.slice(1):
		await press("ui_right")
		check(focused_word() == word, "right reaches %s: %s" % [word, focused_word()])
	await press("ui_right")
	check(focused_word() == "1 Player", "right stops at the end: " + focused_word())
	for step in 8: await press("ui_left")
	check(focused_word() == "Back", "left goes all the way back to Back: " + focused_word())
	await press("ui_left")
	check(focused_word() == "Back", "and stops there: " + focused_word())

func test_up_and_down_move_between_the_rows() -> void:
	await open_play_menu()
	await press("ui_down")
	check(focused_word() in ["Map", "Clock"], "down from Meadow lands just below it: " + focused_word())
	await press("ui_down")
	check(focused_word() in ["Map", "Clock"], "down on the bottom row stays put: " + focused_word())
	await press("ui_up")
	check(focused_word() in ["Back", "Meadow", "Hills"], "up goes back to the top row: " + focused_word())
	await press("ui_up")
	check(focused_word() in ["Back", "Meadow", "Hills"], "up on the top row stays put: " + focused_word())
