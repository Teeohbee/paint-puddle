extends GameSuite
# The grown-ups' Reset row can reset one thing at a time: left and right pick
# Everything, Hills, Meadow, Book words or Book colours; pressing twice resets
# just that and leaves the rest alone.

var settings

func fill_everything():
	settings.reset_progress()
	settings.record_progress("hills_levels_completed", 7)
	settings.record_progress("tasks_completed", 30)
	settings.record_progress("next_task_index", 12)
	settings.record_progress("rainbows_painted", 3)
	settings.set_task_deck(Array([5, 6, 7], TYPE_INT, "", null))
	settings.record_found("words_spelled", "cat")
	settings.record_found("colours_found", "red")
	settings.record_found("book_parts_celebrated", "words")
	settings.record_found("book_parts_celebrated", "colours")

func hills_kept(): return settings.get_progress("hills_levels_completed") == 7
func meadow_kept(): return settings.get_progress("tasks_completed") == 30 and settings.get_progress("next_task_index") == 12 and settings.get_progress("rainbows_painted") == 3 and settings.get_task_deck().size() == 3
func words_kept(): return settings.has_found("words_spelled", "cat") and settings.has_found("book_parts_celebrated", "words")
func colours_kept(): return settings.has_found("colours_found", "red") and settings.has_found("book_parts_celebrated", "colours")

func press(row, action):
	var event = InputEventAction.new()
	event.action = action
	event.pressed = true
	row._gui_input(event)
	await get_tree().process_frame

func test_reset_by_mode() -> void:
	settings = GameSettings
	settings.load_from_disk()

	fill_everything()
	settings.reset_part("hills")
	check(settings.get_progress("hills_levels_completed") == 0, "Hills: levels back to 0")
	check(meadow_kept() and words_kept() and colours_kept(), "Hills: everything else kept")

	fill_everything()
	settings.reset_part("meadow")
	check(settings.get_progress("tasks_completed") == 0 and settings.get_progress("next_task_index") == 0 and settings.get_progress("rainbows_painted") == 0 and settings.get_task_deck().is_empty(), "Meadow: tasks, rainbows and deck back to the start")
	check(hills_kept() and words_kept() and colours_kept(), "Meadow: everything else kept, Book words too")

	fill_everything()
	settings.reset_part("words")
	check(not settings.has_found("words_spelled", "cat") and not settings.has_found("book_parts_celebrated", "words"), "Book words: words gone, and the cheer can happen again")
	check(hills_kept() and meadow_kept() and colours_kept(), "Book words: everything else kept")

	fill_everything()
	settings.reset_part("colours")
	check(not settings.has_found("colours_found", "red") and not settings.has_found("book_parts_celebrated", "colours"), "Book colours: friends gone, and the cheer can happen again")
	check(hills_kept() and meadow_kept() and words_kept(), "Book colours: everything else kept")

	fill_everything()
	settings.reset_part("everything")
	check(settings.get_progress("hills_levels_completed") == 0 and settings.found_in("words_spelled").is_empty() and settings.found_in("colours_found").is_empty() and settings.get_task_deck().is_empty(), "Everything: all of it")

	fill_everything()
	settings.reset_part("hills")
	settings.load_from_disk()
	check(settings.get_progress("hills_levels_completed") == 0 and meadow_kept(), "a part reset is saved")

	# The options screen
	fill_everything()
	get_tree().change_scene_to_file("res://ui/options_screen.tscn")
	await get_tree().create_timer(0.6).timeout
	var screen = get_tree().current_scene
	var row = screen.reset_row
	check(row.choice_word() == "Everything", "the reset row starts on Everything")
	await press(row, "ui_right")
	check(row.choice_word() == "Hills", "right picks Hills")
	await press(row, "ui_accept")
	check(row.message == "Press again" and hills_kept(), "one press asks first: " + row.message)
	await press(row, "ui_accept")
	check(settings.get_progress("hills_levels_completed") == 0 and meadow_kept() and words_kept(), "the second press resets just Hills")
	check(row.message == "Done!", "and says so: " + row.message)
	await press(row, "ui_right")
	await press(row, "ui_accept")
	check(row.choice_word() == "Meadow" and row.message == "Press again", "picking another part asks again")
	await press(row, "ui_left")
	await press(row, "ui_accept")
	check(row.choice_word() == "Hills" and meadow_kept(), "changing the choice cancels the first press")
	await press(row, "ui_left")
	await press(row, "ui_left")
	check(row.choice_word() == "Everything", "left stops at Everything")

