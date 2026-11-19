extends GameSuite
# Clock mode's save: how many rungs are cleared, the climbing rung's deck, the grown-up "open all
# rungs" setting, and the Clock reset part.

func reload() -> void:
	GameSettings.load_from_disk()

func test_a_fresh_game_has_no_rungs_cleared_and_no_deck() -> void:
	check(GameSettings.get_progress("clock_rungs_cleared") == 0, "no rungs cleared")
	check(GameSettings.get_clock_task_deck().is_empty(), "no deck")
	check(GameSettings.get_setting("open_all_clock_rungs") == 0, "rungs aren't all open")

func test_rungs_cleared_and_the_deck_survive_a_reload() -> void:
	GameSettings.record_progress("clock_rungs_cleared", 3)
	var saved_deck: Array[int] = [841, 1080, 33]
	GameSettings.set_clock_task_deck(saved_deck)
	reload()
	check(GameSettings.get_progress("clock_rungs_cleared") == 3, "3 rungs cleared")
	check(GameSettings.get_clock_task_deck() == saved_deck, "the deck kept its order: %s" % [GameSettings.get_clock_task_deck()])

func test_a_save_can_never_have_more_than_8_rungs_cleared() -> void:
	GameSettings.record_progress("clock_rungs_cleared", 40)
	reload()
	check(GameSettings.get_progress("clock_rungs_cleared") == 8, "clamped to 8: %d" % GameSettings.get_progress("clock_rungs_cleared"))

func test_resetting_the_clock_clears_rungs_and_deck_but_never_the_setting() -> void:
	GameSettings.record_progress("clock_rungs_cleared", 5)
	var saved_deck: Array[int] = [841]
	GameSettings.set_clock_task_deck(saved_deck)
	GameSettings.set_setting("open_all_clock_rungs", 1)
	GameSettings.record_progress("hills_levels_completed", 4)
	GameSettings.reset_part("clock")
	check(GameSettings.get_progress("clock_rungs_cleared") == 0 and GameSettings.get_clock_task_deck().is_empty(), "the Clock is cleared")
	check(GameSettings.get_setting("open_all_clock_rungs") == 1, "the setting stays")
	check(GameSettings.get_progress("hills_levels_completed") == 4, "the Hills are left alone")

func test_everything_clears_the_clock_too() -> void:
	GameSettings.record_progress("clock_rungs_cleared", 5)
	var saved_deck: Array[int] = [841]
	GameSettings.set_clock_task_deck(saved_deck)
	GameSettings.reset_part("everything")
	check(GameSettings.get_progress("clock_rungs_cleared") == 0 and GameSettings.get_clock_task_deck().is_empty(), "Everything clears the Clock")

func test_the_clock_reset_part_sits_between_map_and_book_words() -> void:
	var parts: Array = GameSettings.RESET_PARTS.keys()
	check(parts.find("clock") == parts.find("map") + 1 and parts.find("words") == parts.find("clock") + 1, "order: %s" % [parts])
