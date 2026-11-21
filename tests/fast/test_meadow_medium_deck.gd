extends GameSuite
# Medium has its own cards (data/tasks_medium.json), its own deck and its own next card. Playing Medium
# never moves Easy on, and the other way round. Medium has no red paint then wash lesson.

var runner

func open_meadow(difficulty: String) -> void:
	MeadowScript.difficulty = difficulty
	get_tree().change_scene_to_file("res://meadow/meadow.tscn")
	await frames(4)
	runner = get_tree().current_scene.task_runner

func medium_cards() -> Array[MeadowTask]:
	return MeadowTask.load_list(TaskRunner.MEDIUM_TASKS_PATH)

func test_medium_plays_its_own_cards() -> void:
	await open_meadow(TaskRunner.MEDIUM)
	check(runner.tasks.size() == medium_cards().size(), "Medium's pack: %d cards" % runner.tasks.size())
	check(runner.current_task.text == medium_cards()[0].text, "a new Medium starts on its first card: " + runner.current_task.text)

func test_easy_still_plays_the_easy_cards() -> void:
	await open_meadow(TaskRunner.EASY)
	check(runner.tasks.size() == MeadowTask.load_list(TaskRunner.TASKS_PATH).size(), "Easy's pack")
	check(runner.current_task.type == "make" and runner.current_task.paint == "red", "starting on the red paint")

func test_medium_starts_on_its_own_next_card() -> void:
	GameSettings.record_progress("next_task_index", 2)
	GameSettings.record_progress("next_task_index_medium", 4)
	await open_meadow(TaskRunner.MEDIUM)
	check(runner.current_task.text == medium_cards()[4].text, "Medium carries on from its own card")

func test_dealing_on_medium_leaves_easy_alone() -> void:
	GameSettings.set_task_deck(Array([5, 6, 7], TYPE_INT, "", null))
	GameSettings.record_progress("next_task_index", 12)
	await open_meadow(TaskRunner.MEDIUM)
	var dealt: int = runner.deal_next_task_index(0)
	check(GameSettings.get_medium_task_deck().size() == medium_cards().size() - 2, "Medium deals from its own deck: %s" % [GameSettings.get_medium_task_deck()])
	check(not GameSettings.get_medium_task_deck().has(dealt), "the card dealt has left it")
	check(GameSettings.get_task_deck() == Array([5, 6, 7], TYPE_INT, "", null), "Easy's deck is untouched")
	check(GameSettings.get_progress("next_task_index") == 12, "and so is Easy's next card")

func test_finishing_a_medium_card_moves_medium_on() -> void:
	GameSettings.record_progress("next_task_index", 12)
	await open_meadow(TaskRunner.MEDIUM)
	GameSettings.set_medium_task_deck(Array([3], TYPE_INT, "", null))
	runner.finish_task()
	check(GameSettings.get_progress("next_task_index_medium") == 3, "Medium remembers its next card")
	check(GameSettings.get_progress("next_task_index") == 12, "Easy's next card is untouched")
	check(GameSettings.get_progress("tasks_completed") == 1, "a Medium card counts as a card done")

func test_medium_has_no_wash_lesson() -> void:
	await open_meadow(TaskRunner.MEDIUM)
	var seen := {}
	var current: int = 0
	for step in medium_cards().size() * 3:
		current = runner.deal_next_task_index(current)
		seen[current] = true
	check(seen.size() == medium_cards().size(), "every Medium card comes up, the second one too: %s" % [seen.keys()])
	GameSettings.set_medium_task_deck(Array([2, 3], TYPE_INT, "", null))
	check(runner.deal_next_task_index(0) == 3, "the first card isn't always followed by the second")

func test_the_medium_deck_is_saved() -> void:
	GameSettings.set_medium_task_deck(Array([4, 2], TYPE_INT, "", null))
	GameSettings.record_progress("next_task_index_medium", 5)
	GameSettings.load_from_disk()
	check(GameSettings.get_medium_task_deck() == Array([4, 2], TYPE_INT, "", null), "the deck survives a restart")
	check(GameSettings.get_progress("next_task_index_medium") == 5, "and so does the next card")

func test_an_old_save_starts_medium_from_the_beginning() -> void:
	var file := FileAccess.open(GameSettings.save_file_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 2, "progress": {"next_task_index": 7}, "task_deck": [1, 2]}))
	file.close()
	GameSettings.load_from_disk()
	check(GameSettings.get_medium_task_deck().is_empty(), "no Medium deck yet")
	check(GameSettings.get_progress("next_task_index_medium") == 0, "Medium starts on its first card")
	check(GameSettings.get_progress("next_task_index") == 7, "and Easy carries on")
