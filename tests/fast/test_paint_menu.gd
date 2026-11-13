extends GameSuite
# Paint asks which colours: paint colours or printer colours. Controller presses only.

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

func open_paint_menu():
	# Start from a fresh game's play menu, on Meadow
	load("res://ui/menu_screen.gd").last_choices.clear()
	get_tree().change_scene_to_file("res://ui/play_menu.tscn")
	await get_tree().create_timer(0.4).timeout
	await press("ui_right")
	await press("ui_right")
	check(focused_word() == "Paint", "Paint is on the play menu")
	await press("ui_accept")
	return await wait_for_scene("PaintMenu")

func test_paint_menu() -> void:
	var settings = GameSettings
	settings.load_from_disk()
	var studio_script = load("res://paint/paint_studio.gd")

	check(await open_paint_menu(), "Paint asks which colours")
	check(focused_word() == "Paint colours", "it starts on paint colours: " + focused_word())
	await press("ui_accept")
	check(await wait_for_scene("PaintStudio"), "paint colours opens the paper")
	check(studio_script.colour_set == "paint" and get_tree().current_scene.puddles.has("red"), "with red, yellow and blue puddles")

	await open_paint_menu()
	await press("ui_right")
	check(focused_word() == "Printer colours", "right moves to printer colours: " + focused_word())
	await press("ui_accept")
	check(await wait_for_scene("PaintStudio"), "printer colours opens the paper")
	check(studio_script.colour_set == "printer" and get_tree().current_scene.puddles.has("cyan"), "with cyan, magenta and yellow puddles")

	await open_paint_menu()
	check(focused_word() == "Printer colours", "coming back, it starts on the last colours picked: " + focused_word())
	await press("ui_left")
	await press("ui_left")
	check(focused_word() == "Back", "Back is on the left")
	await press("ui_accept")
	check(await wait_for_scene("PlayMenu"), "Back returns to the play menu")

	studio_script.colour_set = "paint"
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://paint_menu_check.json"))
