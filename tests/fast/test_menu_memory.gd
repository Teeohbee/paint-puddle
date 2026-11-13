extends GameSuite
# Coming back to a menu lands on the tile last picked there: the play menu
# on the place played last, the title on Options after Options, the Book on
# the section opened last. Only for this run of the game - never saved.

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
	await get_tree().create_timer(0.25).timeout

func focused():
	return get_tree().root.gui_get_focus_owner()

func open(scene_path):
	get_tree().change_scene_to_file(scene_path)
	await get_tree().create_timer(0.6).timeout

# Picks the focused tile and waits for the scene change to finish
func pick_and_wait():
	await press("ui_accept")
	await get_tree().create_timer(2.0).timeout

func test_menu_memory() -> void:
	var settings = GameSettings
	settings.load_from_disk()

	await open("res://ui/title_screen.tscn")
	check(focused().word == "Play", "a fresh game's title starts on Play")
	await open("res://ui/play_menu.tscn")
	check(focused().word == "Meadow", "a fresh game's play menu starts on Meadow")
	await open("res://ui/book.tscn")
	check(focused().word == "Words", "a fresh game's book starts on Words")

	# Play menu: pick the Book, come back out
	await open("res://ui/play_menu.tscn")
	await press("ui_right")
	await press("ui_right")
	await press("ui_right")
	await press("ui_right")
	await press("ui_right")
	check(focused().word == "Book", "right five times is the Book")
	await pick_and_wait()
	check(get_tree().current_scene.scene_file_path == "res://ui/book.tscn", "the Book opened")
	# Open Colours, then Back, Back to the play menu
	await press("ui_right")
	check(focused().word == "Colours", "right goes to Colours")
	await press("ui_accept")
	check(get_tree().current_scene.section == "colours", "Colours opened")
	get_tree().current_scene.back_tile.grab_focus()
	await press("ui_accept")
	check(focused().word == "Colours", "Back from Colours lands on Colours")
	await press("ui_left")
	await press("ui_left")
	check(focused().word == "Back", "left twice is Back")
	await pick_and_wait()
	check(get_tree().current_scene.scene_file_path == "res://ui/play_menu.tscn" and focused().word == "Book", "out of the Book, the play menu is on the Book")
	await open("res://ui/book.tscn")
	check(focused().word == "Colours", "and the Book opens on Colours next time")

	# Play menu remembers Hills too
	await open("res://ui/play_menu.tscn")
	await press("ui_left")
	await press("ui_left")
	await press("ui_left")
	await press("ui_left")
	check(focused().word == "Hills", "left four times from the Book is Hills")
	await pick_and_wait()
	await open("res://ui/play_menu.tscn")
	check(focused().word == "Hills", "coming back, the play menu is on Hills")

	# Title: Options, then back
	await open("res://ui/title_screen.tscn")
	check(focused().word == "Play", "the title is on Play after playing")
	await press("ui_left")
	check(focused().word == "Options", "left is Options")
	await pick_and_wait()
	check(get_tree().current_scene.scene_file_path == "res://ui/options_screen.tscn", "Options opened")
	await open("res://ui/title_screen.tscn")
	check(focused().word == "Options", "back from Options, the title is on Options")

	var saved_text = FileAccess.get_file_as_string(ProjectSettings.globalize_path(settings.save_file_path))
	check(not saved_text.contains("last_choice"), "menu memory isn't saved")
