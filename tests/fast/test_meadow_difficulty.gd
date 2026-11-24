extends GameSuite
# The Meadow has an Easy / Medium screen, like the Hills. Medium opens once Easy has dealt every card once,
# or early with "Open Medium" in the grown-up settings.


func tile(word):
	for each in get_tree().current_scene.find_children("*", "MenuTile", true, false):
		if each.word == word: return each
	return null

func focused_word():
	var owner = get_tree().root.gui_get_focus_owner()
	return owner.word if owner != null and "word" in owner else "(nothing)"

func open_difficulty_menu() -> void:
	get_tree().change_scene_to_file("res://ui/meadow_difficulty_menu.tscn")
	await frames(4)

func easy_card_count() -> int:
	return MeadowTask.load_list(TaskRunner.TASKS_PATH).size()

func test_the_meadow_tile_opens_the_difficulty_screen() -> void:
	MenuScreen.last_choices.erase("play_menu")
	get_tree().change_scene_to_file("res://ui/play_menu.tscn")
	await frames(4)
	tile("Meadow").chosen.emit()
	var new_scene = await SceneManager.scene_changed
	check(new_scene.scene_file_path == "res://ui/meadow_difficulty_menu.tscn", "Meadow goes to Easy or Medium: " + new_scene.scene_file_path)

func test_the_screen_is_called_meadow_with_easy_and_medium() -> void:
	await open_difficulty_menu()
	var labels = get_tree().current_scene.find_children("*", "Label", true, false).map(func(label): return label.text)
	check(labels.has("Meadow"), "the heading says Meadow: %s" % [labels])
	check(tile("Easy") != null and tile("Medium") != null and tile("Back") != null, "Back, Easy and Medium")

func test_medium_is_locked_on_a_new_save() -> void:
	await open_difficulty_menu()
	check(tile("Medium").is_locked, "Medium is locked")
	check(not tile("Easy").is_locked, "Easy is open")
	check(focused_word() == "Easy", "it starts on Easy: " + focused_word())

func test_medium_stays_locked_until_every_easy_card_is_dealt() -> void:
	GameSettings.record_progress("tasks_completed", easy_card_count() - 1)
	check(not TaskRunner.is_medium_unlocked(), "one card short, Medium is still locked")
	GameSettings.record_progress("tasks_completed", easy_card_count())
	check(TaskRunner.is_medium_unlocked(), "every Easy card done once, Medium opens")
	await open_difficulty_menu()
	check(not tile("Medium").is_locked, "and its tile is open")

func test_open_medium_in_the_grown_up_settings_opens_it() -> void:
	GameSettings.set_setting("open_hills_medium", 1)
	check(TaskRunner.is_medium_unlocked(), "Open Medium opens the Meadow's Medium too")
	check(GameSettings.get_progress("tasks_completed") == 0, "without counting any cards done")

func test_a_locked_medium_does_nothing() -> void:
	await open_difficulty_menu()
	tile("Medium").pressed.emit()
	await frames(2)
	check(not SceneManager.is_changing_scene, "a locked Medium stays put")

func test_picking_medium_plays_the_meadow_on_medium() -> void:
	GameSettings.set_setting("open_hills_medium", 1)
	await open_difficulty_menu()
	tile("Medium").chosen.emit()
	var new_scene = await SceneManager.scene_changed
	check(MeadowScript.difficulty == TaskRunner.MEDIUM, "the Meadow is on Medium")
	check(new_scene.scene_file_path == "res://meadow/meadow.tscn", "and it goes to the Meadow")
	check(new_scene.task_runner.difficulty == TaskRunner.MEDIUM, "its cards are Medium's")

func test_picking_easy_plays_the_meadow_on_easy() -> void:
	MeadowScript.difficulty = TaskRunner.MEDIUM
	await open_difficulty_menu()
	tile("Easy").chosen.emit()
	await SceneManager.scene_changed
	check(MeadowScript.difficulty == TaskRunner.EASY, "the Meadow is back on Easy")

func test_coming_back_lands_on_the_difficulty_played_last() -> void:
	GameSettings.set_setting("open_hills_medium", 1)
	MenuScreen.remember_choice("meadow_difficulty", TaskRunner.MEDIUM)
	await open_difficulty_menu()
	check(focused_word() == "Medium", "back on Medium: " + focused_word())

func test_back_goes_to_the_play_menu() -> void:
	await open_difficulty_menu()
	tile("Back").chosen.emit()
	var new_scene = await SceneManager.scene_changed
	check(new_scene.scene_file_path == "res://ui/play_menu.tscn", "Back is the play menu")
