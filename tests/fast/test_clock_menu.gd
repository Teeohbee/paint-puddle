extends GameSuite
# The Clock menu's layout: Back on its own on the left of the rungs, Tricky on its own on the right.

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

func open_menu() -> Control:
	get_tree().change_scene_to_file("res://ui/clock_menu.tscn")
	await frames(4)
	return get_tree().current_scene

func rect_of(tile) -> Rect2:
	return tile.get_global_rect()

func test_back_and_tricky_stand_either_side_of_the_rungs() -> void:
	GameSettings.record_progress("clock_rungs_cleared", 2)
	var menu = await open_menu()
	var first_rung = rect_of(menu.rung_tiles[0])
	var last_rung = rect_of(menu.rung_tiles[-1])
	var grid_middle_y = (first_rung.position.y + last_rung.end.y) / 2.0
	check(rect_of(menu.back).end.x < first_rung.position.x, "Back is left of the rungs")
	check(absf(rect_of(menu.back).get_center().y - grid_middle_y) < 1.0, "Back is halfway down the rungs: %s vs %s" % [rect_of(menu.back).get_center().y, grid_middle_y])
	check(rect_of(menu.tricky).position.x > last_rung.end.x, "Tricky is right of the rungs")
	check(absf(rect_of(menu.tricky).get_center().y - grid_middle_y) < 1.0, "Tricky is halfway down the rungs: %s vs %s" % [rect_of(menu.tricky).get_center().y, grid_middle_y])
	var screen = Rect2(Vector2.ZERO, Vector2(1920, 1080))
	for tile in [menu.back, menu.tricky] + menu.rung_tiles:
		check(screen.encloses(rect_of(tile)), "%s is on the screen" % tile.word)

func test_left_and_right_reach_back_and_tricky_from_either_row() -> void:
	GameSettings.record_progress("clock_rungs_cleared", 7)
	var menu = await open_menu()
	for start in [0, 4]:
		menu.rung_tiles[start].grab_focus()
		await frames(1)
		for step in 4: await press("ui_left")
		check(focused_word() == "Back", "left from rung %d reaches Back: %s" % [start + 1, focused_word()])
		menu.rung_tiles[start].grab_focus()
		await frames(1)
		for step in 5: await press("ui_right")
		check(focused_word() == "Tricky", "right from rung %d reaches Tricky: %s" % [start + 1, focused_word()])
