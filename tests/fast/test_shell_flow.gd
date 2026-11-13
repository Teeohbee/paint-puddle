extends GameSuite
# Walks the whole shell on "controller" presses only: splash, title, play,
# meadow, pause, restart, home, options, back, and the unplugged notice.

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
	await get_tree().create_timer(0.15).timeout

func focused_word():
	var owner = get_tree().root.gui_get_focus_owner()
	return owner.word if owner != null and "word" in owner else "(nothing)"

func wait_for_scene(scene_name, seconds = 3.0):
	var waited = 0.0
	while (get_tree().current_scene == null or get_tree().current_scene.name != scene_name or SceneManager.is_changing_scene) and waited < seconds:
		await get_tree().create_timer(0.1).timeout
		waited += 0.1
	await get_tree().create_timer(0.2).timeout
	return get_tree().current_scene != null and get_tree().current_scene.name == scene_name

func test_shell_flow() -> void:
	var settings = GameSettings
	settings.load_from_disk()
	settings.reset_progress()
	get_tree().change_scene_to_file("res://ui/splash_screen.tscn")
	await get_tree().create_timer(0.5).timeout
	await press("act")
	check(await wait_for_scene("TitleScreen"), "any button skips the splash to the title")
	check(focused_word() == "Play", "the title starts on Play: " + focused_word())
	await press("ui_left")
	check(focused_word() == "Options", "left moves to Options")
	await press("ui_right")
	await press("ui_accept")
	check(await wait_for_scene("PlayMenu"), "Play opens the play menu")
	check(focused_word() == "Meadow", "the play menu starts on Meadow")
	await press("ui_right")
	check(focused_word() == "Hills", "right moves to Hills")
	await press("ui_accept")
	check(await wait_for_scene("HillsDifficultyMenu"), "Hills opens the Easy or Medium menu")
	check(focused_word() == "Easy", "it starts on Easy: " + focused_word())
	await press("ui_accept")
	check(await wait_for_scene("HillsMenu"), "Easy opens the Rainbow Hills menu")
	check(focused_word() == "Walk", "the hills menu starts on the first open level: " + focused_word())
	await press("ui_right")
	check(focused_word() == "Hop", "right moves to Hop")
	await press("ui_accept")
	await get_tree().create_timer(0.4).timeout
	check(get_tree().current_scene.name == "HillsMenu", "a locked level does nothing")
	await press("ui_left")
	await press("ui_left")
	await press("ui_accept")
	check(await wait_for_scene("HillsDifficultyMenu"), "Back returns to the Easy or Medium menu")
	check(focused_word() == "Easy", "back on Easy: " + focused_word())
	await press("ui_left")
	await press("ui_accept")
	check(await wait_for_scene("PlayMenu"), "and its Back returns to the play menu")
	check(focused_word() == "Hills", "back on Hills, the place just visited: " + focused_word())
	await press("ui_left")
	await press("ui_accept")
	check(await wait_for_scene("Meadow"), "Meadow starts the meadow")
	check(Music.wanted_track == "meadow", "the meadow has its own music")

	await press("pause")
	check(get_tree().paused, "Menu pauses the game")
	check(focused_word() == "Play on", "pause starts on Play on: " + focused_word())
	await press("ui_accept")
	check(not get_tree().paused, "Play on carries on")

	await press("pause")
	await press("ui_right")
	check(focused_word() == "Restart", "right moves to Restart")
	var old_meadow = get_tree().current_scene
	await press("ui_accept")
	await get_tree().create_timer(1.2).timeout
	check(get_tree().current_scene.name == "Meadow" and get_tree().current_scene != old_meadow, "Restart starts the meadow afresh")
	check(not get_tree().paused, "and it isn't get_tree().paused")

	await press("pause")
	await press("ui_left")
	check(focused_word() == "Home", "left moves to Home")
	await press("ui_accept")
	check(await wait_for_scene("TitleScreen"), "Home goes back to the title")
	check(not get_tree().paused, "the title isn't get_tree().paused")

	await press("ui_left")
	await press("ui_accept")
	check(await wait_for_scene("OptionsScreen"), "Options opens")
	var music_before = settings.get_setting("music_volume")
	await press("ui_left")
	check(settings.get_setting("music_volume") == music_before - 1, "left turns the music down")
	await press("ui_right")
	check(settings.get_setting("music_volume") == music_before, "right turns it back up")
	await press("ui_down")
	await press("ui_down")
	await press("ui_accept")
	check(await wait_for_scene("TitleScreen"), "Back returns to the title (grown-up rows stay hidden)")
	check(focused_word() == "Options", "back on Options, the tile just picked: " + focused_word())

	await press("ui_right")
	await press("ui_accept")
	await wait_for_scene("PlayMenu")
	check(focused_word() == "Meadow", "the play menu is on Meadow, the place played last: " + focused_word())
	await press("ui_accept")
	await wait_for_scene("Meadow")
	get_tree().current_scene.get_node("PauseMenu").on_joy_connection_changed(0, false)
	await get_tree().process_frame
	var pause_menu = get_tree().current_scene.get_node("PauseMenu")
	check(get_tree().paused and pause_menu.unplugged_notice.visible, "unplugging pauses and asks for the controller")
	pause_menu.on_joy_connection_changed(0, true)
	await get_tree().process_frame
	check(get_tree().paused and not pause_menu.unplugged_notice.visible, "plugging back in shows the pause menu")
	check(focused_word() == "Play on", "ready to play on")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://shell_flow_check.json"))
