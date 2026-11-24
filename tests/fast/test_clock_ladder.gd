extends GameSuite
# The Clock mode ladder: which rungs the menu opens, the climbing rung's saved deck, clearing a
# rung, replays, and the grown-up "open all rungs" setting.

func open_menu() -> Control:
	get_tree().change_scene_to_file("res://ui/clock_menu.tscn")
	await frames(4)
	return get_tree().current_scene

## Opens a rung with its first-time intro already seen, straight onto the cards.
func open_rung(rung: int) -> ClockMode:
	GameSettings.record_progress("clock_rung_intros_seen", maxi(GameSettings.get_progress("clock_rung_intros_seen"), rung))
	ClockMode.rung_to_play = rung
	get_tree().change_scene_to_file("res://clock/clock_mode.tscn")
	await frames(4)
	return get_tree().current_scene

func tap(action: String) -> void:
	Input.action_press(action)
	await frames(2)
	Input.action_release(action)
	await frames(2)

func focused_word() -> String:
	var owner = get_viewport().gui_get_focus_owner()
	return owner.word if owner != null else ""

func locked_rungs(menu) -> Array[int]:
	var locked: Array[int] = []
	for index in menu.rung_tiles.size():
		if menu.rung_tiles[index].is_locked:
			locked.append(index + 1)
	return locked

## Plays a one-card deck at 7 am (a set card for the time the day starts at), so A finishes it.
func finish_a_one_card_deck(mode: ClockMode) -> void:
	var one_card: Array[ClockCard] = [ClockCard.new(false, 7 * 60)]
	mode.task_runner.start_deck(mode.rung, one_card)
	await frames(2)
	await tap("act")
	await frames(roundi(60 * (ClockTaskRunner.SECONDS_TO_CELEBRATE + ClockMode.SECONDS_TO_CHEER + 1.0)))


# ---- the menu

func test_a_fresh_game_has_rung_1_open_and_the_rest_locked() -> void:
	var menu = await open_menu()
	check(not menu.rung_tiles[0].is_locked, "rung 1 is open")
	check(locked_rungs(menu) == [2, 3], "rungs 2 and 3 locked: %s" % [locked_rungs(menu)])

func test_open_all_rungs_leaves_the_count_alone() -> void:
	GameSettings.record_progress("clock_rungs_cleared", 1)
	GameSettings.set_setting("open_all_clock_rungs", 1)
	await open_menu()
	check(GameSettings.get_progress("clock_rungs_cleared") == 1, "rungs cleared unchanged")

func test_picking_a_rung_plays_it() -> void:
	var menu = await open_menu()
	menu.rung_tiles[0].chosen.emit()
	await frames(40)
	var mode = get_tree().current_scene
	check(mode is ClockMode and mode.rung == 1, "rung 1 plays")
	check(not mode.clock_face.shows_minute_hand, "with only the hour hand")


# ---- the climbing rung's deck

func test_the_climbing_rung_saves_its_deck_and_picks_up_where_it_left_off() -> void:
	var mode: ClockMode = await open_rung(1)
	check(mode.is_climbing, "rung 1 is being climbed")
	var saved: Array[int] = GameSettings.get_clock_task_deck()
	check(saved.size() == 8, "a fresh deck of 8 is saved: %d" % saved.size())
	mode.on_card_finished(mode.task_runner.current_card, true)
	check(GameSettings.get_clock_task_deck() == saved.slice(1), "after a card, the 7 still to come are saved")
	mode = await open_rung(1)
	check(mode.task_runner.deck.size() == 7 and mode.task_runner.current_card.saved_number() == saved[1], "coming back carries on from the second card")

func test_finishing_a_deck_without_the_run_clears_nothing() -> void:
	var mode: ClockMode = await open_rung(1)
	await finish_a_one_card_deck(mode)
	check(GameSettings.get_progress("clock_rungs_cleared") == 0, "a finished deck alone clears nothing")
	check(GameSettings.get_progress("clock_first_try_run") == 1, "but the first try counts: %d" % GameSettings.get_progress("clock_first_try_run"))
	check(get_tree().current_scene.scene_file_path == "res://ui/clock_menu.tscn", "back on the Clock menu")

# Day one's run of 5 was another day, and 4 of today's are in: one more first try clears the rung
func test_clearing_the_climbing_rung_opens_the_next_and_goes_back_to_the_menu_on_it() -> void:
	GameSettings.record_progress("clock_run_day", 20000101)
	GameSettings.record_progress("clock_first_try_run", 4)
	var mode: ClockMode = await open_rung(1)
	await finish_a_one_card_deck(mode)
	check(GameSettings.get_progress("clock_rungs_cleared") == 1, "one rung cleared: %d" % GameSettings.get_progress("clock_rungs_cleared"))
	check(GameSettings.get_clock_task_deck().is_empty(), "the deck is cleared")
	check(get_tree().current_scene.scene_file_path == "res://ui/clock_menu.tscn", "back on the Clock menu")
	check(focused_word() == get_tree().current_scene.free_play.word, "the next rung isn't built, so on Play with the clock: '%s'" % focused_word())

func test_a_replay_saves_nothing_and_counts_nothing() -> void:
	GameSettings.record_progress("clock_rungs_cleared", 2)
	GameSettings.record_progress("clock_run_day", 20000101)
	GameSettings.record_progress("clock_first_try_run", 4)
	var mode: ClockMode = await open_rung(1)
	check(not mode.is_climbing, "rung 1 is a replay")
	check(GameSettings.get_clock_task_deck().is_empty(), "no deck saved")
	await finish_a_one_card_deck(mode)
	check(GameSettings.get_progress("clock_rungs_cleared") == 2, "still 2 cleared")
	check(GameSettings.get_progress("clock_first_try_run") == 4, "and the run is the climbing rung's, untouched")

func test_a_rung_opened_by_a_grown_up_isnt_climbed() -> void:
	GameSettings.set_setting("open_all_clock_rungs", 1)
	GameSettings.record_progress("clock_rung_intros_seen", 8)
	var mode: ClockMode = await open_rung(5)
	check(not mode.is_climbing, "rung 5 isn't being climbed")
	await finish_a_one_card_deck(mode)
	check(GameSettings.get_progress("clock_rungs_cleared") == 0, "nothing cleared")
