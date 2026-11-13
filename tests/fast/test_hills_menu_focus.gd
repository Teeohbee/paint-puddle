extends GameSuite
# After a level, the Hills menu waits on the level after the one just played,
# even when that's a replay of an early level. From the play menu it starts on
# the latest open level.

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

func focused_word():
	var owner = get_tree().root.gui_get_focus_owner()
	return owner.word if owner != null and "word" in owner else "(nothing)"

func wait_for_scene(scene_name, seconds = 12.0):
	var waited = 0.0
	while (get_tree().current_scene == null or get_tree().current_scene.name != scene_name or SceneManager.is_changing_scene) and waited < seconds:
		await get_tree().create_timer(0.1).timeout
		waited += 0.1
	await get_tree().create_timer(0.3).timeout
	return get_tree().current_scene != null and get_tree().current_scene.name == scene_name

func finish_level(level_index):
	var hills_level_script = load("res://hills/hills_level.gd")
	hills_level_script.level_to_play = level_index
	get_tree().change_scene_to_file("res://hills/hills_level.tscn")
	await get_tree().create_timer(0.5).timeout
	get_tree().current_scene.finish()
	return await wait_for_scene("HillsMenu")

func level_name(level_index):
	return load("res://hills/hills_levels.gd").LEVELS[level_index].name

func open_menu_from_play_menu():
	get_tree().change_scene_to_file("res://ui/play_menu.tscn")
	await get_tree().create_timer(0.5).timeout
	SceneManager.go_to("res://ui/hills_menu.tscn")
	return await wait_for_scene("HillsMenu")

func test_hills_menu_focus() -> void:
	var settings = GameSettings
	settings.load_from_disk()
	settings.reset_progress()
	var level_count = load("res://hills/hills_levels.gd").level_count()
	settings.record_progress("hills_levels_completed", 7)

	check(await finish_level(2), "finishing a level goes back to the Hills menu")
	check(focused_word() == level_name(3), "replaying level 3 waits on level 4: " + focused_word())
	check(settings.get_progress("hills_levels_completed") == 7, "a replay doesn't change progress")

	check(await open_menu_from_play_menu(), "the play menu opens the Hills menu")
	check(focused_word() == level_name(7), "from the play menu it starts on the latest open level: " + focused_word())

	await finish_level(7)
	check(focused_word() == level_name(8), "finishing the latest level waits on the one it unlocked: " + focused_word())

	settings.record_progress("hills_levels_completed", level_count)
	await finish_level(level_count - 1)
	check(focused_word() == level_name(level_count - 1), "finishing the last level stays on it: " + focused_word())

	# Twenty levels to a page
	var per_page = 20
	settings.reset_progress()
	settings.record_progress("hills_levels_completed", 14)
	await open_menu_from_play_menu()
	check(get_tree().current_scene.page == 0, "level 15 is on page one")
	check(focused_word() == level_name(14), "with 15 open it starts on level 15: " + focused_word())
	if level_count <= per_page:
		for step in 8: await press("ui_right")
		check(focused_word() != "More", "no More tile while every level fits on one page: " + focused_word())
	else:
		settings.reset_progress()
		settings.record_progress("hills_levels_completed", 24)
		await open_menu_from_play_menu()
		check(focused_word() == level_name(24), "with 25 open it starts on level 25, on the second page: " + focused_word())
		check(get_tree().current_scene.page == 1, "which is page two")
		for step in 5: await press("ui_left")
		check(focused_word() == "Back", "Back is on the left of page two: " + focused_word())
		await press("ui_accept")
		await get_tree().create_timer(0.3).timeout
		check(get_tree().current_scene.name == "HillsMenu" and get_tree().current_scene.page == 0, "Back on page two goes to page one")
		check(focused_word() == "More", "waiting on More: " + focused_word())
		await press("ui_accept")
		await get_tree().create_timer(0.3).timeout
		check(get_tree().current_scene.page == 1 and focused_word() == level_name(per_page), "More shows page two, on its first level: " + focused_word())
		await finish_level(per_page - 1)
		check(focused_word() == level_name(per_page) and get_tree().current_scene.page == 1, "replaying level 20 waits on level 21, over on page two: " + focused_word())
		settings.reset_progress()
		settings.record_progress("hills_levels_completed", 4)
		await open_menu_from_play_menu()
		check(get_tree().current_scene.page == 0, "early on it opens on page one")
		for step in 6: await press("ui_right")
		check(focused_word() == "More", "right along the row reaches More: " + focused_word())
		await press("ui_accept")
		await get_tree().create_timer(0.3).timeout
		check(get_tree().current_scene.page == 0, "More stays locked until level 20 is done")

	settings.reset_progress()
