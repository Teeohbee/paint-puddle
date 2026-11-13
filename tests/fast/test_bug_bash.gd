extends GameSuite
# Regression checks for the bugs found in the 2026-10-27 bug bash.

func press_action(action):
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

## A real controller A press: it's both ui_accept and act at once.
func press_a_button():
	var event = InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_A
	event.pressed = true
	Input.parse_input_event(event)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	event = InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_A
	event.pressed = false
	Input.parse_input_event(event)
	await get_tree().create_timer(0.15).timeout

func wait_for_scene(scene_name, seconds = 3.0):
	var waited = 0.0
	while (get_tree().current_scene == null or get_tree().current_scene.name != scene_name or SceneManager.is_changing_scene) and waited < seconds:
		await get_tree().create_timer(0.1).timeout
		waited += 0.1
	await get_tree().create_timer(0.2).timeout
	return get_tree().current_scene != null and get_tree().current_scene.name == scene_name

func test_bug_bash() -> void:
	await get_tree().process_frame
	var settings = GameSettings
	var scene_manager = SceneManager
	var music = Music
	settings.load_from_disk()
	settings.reset_progress()

	# Leaving through the pause menu must give the music its volume back
	scene_manager.go_to("res://meadow/meadow.tscn")
	await wait_for_scene("Meadow")
	await press_action("pause")
	await press_action("ui_left")
	await press_action("ui_accept")
	await wait_for_scene("TitleScreen")
	await get_tree().create_timer(0.5).timeout
	check(is_equal_approx(music.duck_effect.volume_db, 0.0), "Home from pause un-ducks the music: %s dB" % music.duck_effect.volume_db)

	# Choosing Play on with A mustn't also make the blob jump
	load("res://hills/hills_level.gd").level_to_play = 0
	scene_manager.go_to("res://hills/hills_level.tscn")
	await wait_for_scene("HillsLevel")
	await get_tree().create_timer(0.5).timeout
	var blob = get_tree().current_scene.blob
	await press_action("pause")
	var jumps_before = blob.mover.jumps_made
	await press_a_button()
	await get_tree().create_timer(0.3).timeout
	check(not get_tree().paused, "A on Play on carries on")
	check(blob.mover.jumps_made == jumps_before, "A on Play on doesn't make the blob jump")

	# Falling back into a gap after turning round still lands on ground
	load("res://hills/hills_level.gd").level_to_play = 2
	scene_manager.go_to("res://hills/hills_level.tscn")
	await wait_for_scene("HillsLevel")
	await get_tree().create_timer(0.3).timeout
	var level = get_tree().current_scene
	blob = level.blob
	var gap_left_edge = level.ground.ground_tops[0][level.ground.ground_tops[0].size() - 1].x
	blob.position = Vector2(gap_left_edge - 20, level.ground.height_at(gap_left_edge - 20) - 60)
	await get_tree().create_timer(0.3).timeout
	# Wanders off the edge facing right, then turns round in the air
	blob.position.x = gap_left_edge + 60
	blob.facing = -1.0
	var rescues = 0
	var was_carried = false
	for frame in 300:
		await get_tree().physics_frame
		if blob.is_being_carried and not was_carried:
			rescues += 1
		was_carried = blob.is_being_carried
	check(rescues == 1, "one rescue puts the blob back on ground: %d rescues" % rescues)
	check(blob.is_on_floor(), "the rescued blob is standing on ground")

	# A collect task with more drops than the meadow has room for is refused
	var too_many = load("res://core/meadow_task.gd").from_dictionary({"type": "collect", "paint": "red", "count": 14, "text": "Too many"})
	check(too_many == null, "a collect task that won't fit with its decoys is refused")
	var too_many_choices = load("res://core/meadow_task.gd").from_dictionary({"type": "sum", "answer": 1,
		"choices": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16], "text": "Too many"})
	check(too_many_choices == null, "a sum with more choices than spots is refused")

	# New stones never appear under the blob, where they'd be picked for free
	var put_under_the_blob = 0
	for attempt in 6:
		scene_manager.go_to("res://meadow/meadow.tscn")
		await wait_for_scene("Meadow")
		var meadow = get_tree().current_scene
		var runner = meadow.task_runner
		runner.clear_the_grass()
		meadow.blob.position = load("res://meadow/task_runner.gd").FREE_SPOTS[attempt]
		runner.current_task = load("res://core/meadow_task.gd").from_dictionary({"type": "spell", "word": "ABCDEFGHIJKL", "text": "x"})
		runner.put_things_in_the_grass()
		for thing in runner.things_in_the_grass:
			if thing.position.distance_to(meadow.blob.position) < 150.0:
				put_under_the_blob += 1
	check(put_under_the_blob == 0, "no stone is put under the blob: %d were" % put_under_the_blob)

	# Unplugging mid-wipe doesn't leave the pause menu showing only the notice
	scene_manager.go_to("res://meadow/meadow.tscn")
	await scene_manager.scene_changed
	Input.joy_connection_changed.emit(0, false)
	await wait_for_scene("Meadow")
	var pause_menu = get_tree().current_scene.get_node("PauseMenu")
	check(pause_menu.is_open and pause_menu.unplugged_notice.visible, "an unplug mid-wipe still pauses once the wipe is done")
	await press_action("pause")
	await press_action("pause")
	check(pause_menu.is_open, "pause opens again afterwards")
	check(pause_menu.tiles_holder.visible and not pause_menu.unplugged_notice.visible, "and shows its tiles, not the notice")
	await press_action("pause")

	# Leaving the meadow straight after a task leaves no stranded coroutine errors
	get_tree().current_scene.task_runner.finish_task()
	scene_manager.go_to("res://ui/title_screen.tscn")
	await wait_for_scene("TitleScreen")
	await get_tree().create_timer(3.5).timeout
	print("(look for errors above this line)")

	# A hand-edited save with negative progress still opens the hills menu
	var file = FileAccess.open(settings.save_file_path, FileAccess.WRITE)
	file.store_string('{"version": 1, "progress": {"hills_levels_completed": -3, "next_task_index": -5}}')
	file.close()
	settings.load_from_disk()
	check(settings.get_progress("hills_levels_completed") == 0 and settings.get_progress("next_task_index") == 0, "negative progress loads as 0")
	scene_manager.go_to("res://ui/hills_menu.tscn")
	check(await wait_for_scene("HillsMenu"), "the hills menu opens")
	check(get_tree().root.gui_get_focus_owner() != null, "with a level to start on")

