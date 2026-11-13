extends GameSuite
# A scene change hides behind the paint, freezes both scenes while it does, and sets the game speed for
# gameplay but never for menus.

func test_scene_manager() -> void:
	var manager = SceneManager
	var settings = GameSettings
	settings.load_from_disk()
	settings.set_setting("game_speed_percent", 70)
	get_tree().change_scene_to_file("res://ui/title_screen.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	var first_scene = get_tree().current_scene

	check(manager.go_to("res://meadow/meadow.tscn"), "a change starts")
	check(not manager.go_to("res://meadow/meadow.tscn"), "a second press during the change is ignored")
	await get_tree().create_timer(0.1).timeout
	check(first_scene.process_mode == Node.PROCESS_MODE_DISABLED, "the old scene is frozen while the paint covers it")

	await get_tree().create_timer(0.5).timeout
	check(get_tree().current_scene.name == "Meadow", "the new scene is in place")
	check(get_tree().current_scene.process_mode == Node.PROCESS_MODE_DISABLED, "the new scene is frozen while the paint uncovers it")
	check(is_equal_approx(Engine.time_scale, 0.7), "gameplay runs at the chosen game speed")

	await get_tree().create_timer(0.6).timeout
	check(not manager.is_changing_scene, "the change finishes")
	check(get_tree().current_scene.process_mode == Node.PROCESS_MODE_INHERIT, "the new scene comes alive")
	check(manager.coverage == 0.0, "the paint has gone")

	manager.go_to("res://ui/title_screen.tscn")
	await get_tree().create_timer(1.2).timeout
	check(Engine.time_scale == 1.0, "menus always run at full speed")
